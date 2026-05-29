using Microsoft.EntityFrameworkCore;
using TenderGo.Api.Database;
using TenderGo.Data;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;

namespace TenderGo.Recommender;

public class TenderRecommendationProvider
{
    private readonly TenderGoContext _context;
    private readonly TenderVectorBuilder _vectorBuilder;
    private readonly RecommenderService _recommenderService;

    public TenderRecommendationProvider(
        TenderGoContext context,
        TenderVectorBuilder vectorBuilder,
        RecommenderService recommenderService)
    {
        _context = context;
        _vectorBuilder = vectorBuilder;
        _recommenderService = recommenderService;
    }

    public async Task<List<ScoredTender>> GetPersonalizedRecommendationsAsync(string userId, int topN = 10)
    {
        // =================================================================
        // KORAK 1: Povlačenje sirove istorije aktivnosti korisnika iz baze
        // =================================================================
        var activities = await _context.UserActivities
            .Include(a => a.Tender) // Uključujemo i podatke o tenderu ako je rađen 'View'
                .ThenInclude(t => t.Category)
            .Include(a => a.Tender)
                .ThenInclude(t => t.Location)
            .Where(a => a.UserId == userId)
            .OrderByDescending(a => a.Timestamp)
            .Take(20) // Uzimamo zadnjih 20 akcija radi svježine preporuka
            .ToListAsync();

        // Ako korisnik nema nikakve istorije (novi profil), vrati defaultne/najnovije tendere
        if (!activities.Any())
        {
            return await GetDefaultRecommendationsAsync(topN);
        }

        // =================================================================
        // KORAK 2: SPAJANJE I KREIRANJE FIKTIVNOG TENDERA (U MEMORIJI)
        // =================================================================
        // Agregiramo podatke iz istorije da sklopimo "idealan" tender profil
        
        var fiktivniTender = new Tender
        {
            Id = 0, // 0 jer ne postoji u bazi podataka!
            Title = "Fiktivni Target",
            Description = "", // Puniće se iz pretraga
            Status = TenderStatus.Open
        };

        // 2a. Skupljanje ključnih riječi iz pretraga (SearchQuery) i spajanje u opis
        var searchQueries = activities
            .Where(a => a.ActivityType == "Search" && !string.IsNullOrEmpty(a.SearchQuery))
            .Select(a => a.SearchQuery);
        
        fiktivniTender.Description = string.Join(" ", searchQueries);

        // 2b. Određivanje dominantne kategorije i lokacije na osnovu kliknutih ('View') tendera
        var viewedTenders = activities
            .Where(a => a.ActivityType == "View" && a.Tender != null)
            .Select(a => a.Tender!)
            .ToList();

        if (viewedTenders.Any())
        {
            // Uzimamo kategoriju koja se najčešće pojavljuje u klikovima (Mode)
            var dominantCategory = viewedTenders
                .GroupBy(t => t.CategoryId)
                .OrderByDescending(g => g.Count())
                .First().FirstOrDefault();

            if (dominantCategory != null)
            {
                fiktivniTender.CategoryId = dominantCategory.CategoryId;
                fiktivniTender.Category = dominantCategory.Category;
            }

            // Uzimamo lokaciju koja se najčešće pojavljuje u klikovima
            var dominantLocation = viewedTenders
                .Where(t => t.Location != null)
                .GroupBy(t => t.LocationId)
                .OrderByDescending(g => g.Count())
                .First().FirstOrDefault()?.Location;

            if (dominantLocation != null)
            {
                fiktivniTender.LocationId = dominantLocation.Id;
                fiktivniTender.Location = dominantLocation;
            }

            // Računamo prosječan budžet koji je korisnik gledao
            fiktivniTender.MaxBudget = viewedTenders.Average(t => t.MaxBudget);
        }

        // =================================================================
        // KORAK 3: PROSLJEĐIVANJE U TENDERVECTORBUILDER
        // =================================================================
        // Pretvaramo naš fiktivni tender (RAM memorija) u osobinu-vektor (target)
        TenderFeatureVector targetVector = _vectorBuilder.Build(fiktivniTender);

        // =================================================================
        // KORAK 4: KANDIDATI I POREĐENJE KROZ RECOMMENDER SERVICE
        // =================================================================
        // Povlačimo sve stvarne OTVORENE tendere iz baze koji će se porediti sa našim targetom
        var openTendersFromDb = await _context.Tenders
            .Include(t => t.Category)
            .Include(t => t.Location)
            .Where(t => t.Status == TenderStatus.Open)
            .ToListAsync();

        // Pretvaramo sve baze-tendere u vektore kandidate
        var candidateVectors = openTendersFromDb.Select(t => _vectorBuilder.Build(t));

        // Pokrećemo tvoj RecommenderService matematički engine (Kosinusna sličnost)
        List<ScoredTender> recommendations = _recommenderService.GetSimilar(targetVector, candidateVectors, topN);

        return recommendations;
    }

    private async Task<List<ScoredTender>> GetDefaultRecommendationsAsync(int topN)
    {
        // Fallback logika: ako je korisnik skroz nov, vrati top-N najnovijih otvorenih tendera
        return await _context.Tenders
            .Where(t => t.Status == TenderStatus.Open)
            .OrderByDescending(t => t.Id)
            .Take(topN)
            .Select(t => new ScoredTender { TenderId = t.Id, Title = t.Title, Score = 1.0 })
            .ToListAsync();
    }
}
