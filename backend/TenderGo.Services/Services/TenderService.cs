using AutoMapper;
using AutoMapper.QueryableExtensions;
using EasyNetQ;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.NetworkInformation;
using System.Reflection.Metadata;
using System.Security.Claims;
using System.Text;
using System.Threading.Channels;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;
using TenderGo.Services.StateMachines.TenderStates;

namespace TenderGo.Services.Services
{
    public class TenderService : BaseService<TenderDTO, Tender, TenderInsertRequest, TenderUpdateRequest>, ITenderService
    {

        private readonly IAuthService _authService;
        protected readonly ILogger<TenderService> _logger;
        protected readonly IServiceProvider _serviceProvider;
        protected readonly IImageService _imageService;
        protected readonly IBidService _bidService;
        private readonly IMemoryCache _cache;

        private const string CacheKey = "active_tenders";
        public TenderService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor, IAuthService authService, ILogger<TenderService> logger, IServiceProvider serviceProvider, IImageService imageService, IBidService bidService,IMemoryCache cache) : base(context, mapper, httpContextAccessor)
        {
            _logger = logger;
            _authService = authService;
            _serviceProvider = serviceProvider;
            _imageService = imageService;
            _bidService = bidService;
            _cache = cache;
        }

        protected override IQueryable<Tender> AddIncludes(IQueryable<Tender> query)
        {
            return query
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Bids)
                .Include(t => t.Images);
        }

        public async Task<IEnumerable<TenderDTO>> GetActiveTenders()
        {
            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)  
                .Include(t => t.Images)
                .Where(t => t.Status == TenderStatus.Open)
                .ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }
        public async Task<IEnumerable<TenderDTO>> GetClosedTenders()
        {
            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Images)
                .Where(t => t.Status == TenderStatus.Closed)
                .ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }

      
        public async Task<IEnumerable<TenderDTO>> GetCancelledTenders()
        {
            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Images)
                .Where(t => t.Status == TenderStatus.Cancelled)
                .ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }

        public async Task<IEnumerable<TenderDTO>> GetTendersByCategory(int id)
        {
            var categoryExists = await _context.Categories.AnyAsync(c => c.Id == id);
            if (!categoryExists)
                throw new NotFoundException("Category not found", new { CategoryId = id });

            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Images)
                .Where(t => t.CategoryId == id)
                .ToListAsync();
            return _mapper.Map<IEnumerable<TenderDTO>>(tenders);
        }

        public async Task<List<TenderDTO>> GetTendersByUser(string userId)
        {
            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (userId != currentUserId && !isAdmin)
            {
                throw new UnauthorizedException("You dont have permission to see other's tenders.");

            }
            var tenders = await _context.Tenders
                .Include(t => t.Category)
                .Include(t => t.CreatedByUser)
                .Include(t => t.Images)
                .Where(t => t.CreatedByUserId == userId)
                .OrderByDescending(t => t.CreatedAt)
                .ToListAsync();
            return _mapper.Map<List<TenderDTO>>(tenders);
        }


        public override async Task<TenderDTO> Insert(TenderInsertRequest request)
        {
            _logger.LogInformation("Posting tender {Title}", request.Title);

            if (request.Deadline <= DateTime.UtcNow)
                throw new UserException("Deadline must be in the future");

            try  
            {
               

                if(request.LocationId <= 0)
{
                    throw new UserException("Location is required.");
                }

                var location = await _context.Locations.FindAsync(request.LocationId);
                if (location == null)
                {
                    throw new UserException("The selected location does not exist in our database.");
                }

                var entity = _mapper.Map<Tender>(request);


                entity.LocationId = location.Id;
                entity.Status = TenderStatus.Open;
                entity.PostedAt = DateTime.UtcNow;
                entity.CreatedAt = DateTime.UtcNow;
                entity.CreatedByUserId = _authService.GetCurrentUserId();

                _context.Tenders.Add(entity);

                if (request.ImageBytes != null && request.ImageBytes.Any())
                {
                    entity.Images = new List<TenderImage>();
                    for (int i = 0; i < request.ImageBytes.Count; i++)
                    {

                        var bytes = request.ImageBytes[i];
                        var hash = await _imageService.CalculateHash(bytes);

                        var existingImage = await _context.TenderImages
                            .FirstOrDefaultAsync(img => img.ImageHash == hash);

                        if (existingImage != null)
                        {
                            entity.Images.Add(new TenderImage
                            {
                                ImageUrl = existingImage.ImageUrl,
                                ImageHash = hash,
                                IsPrimary = i == 0
                            });
                        }
                        else
                        {
                            var uploadResult = await _imageService.UploadImageAsync(bytes, "tenders", i == 0);
                            entity.Images.Add(new TenderImage
                            {
                                ImageUrl = uploadResult.ImageUrl,
                                ImageHash = hash,
                                IsPrimary = i == 0
                            });
                        }
                    }
                }

                await _context.SaveChangesAsync();

                var saved = await _context.Tenders
                    .Include(t => t.CreatedByUser)
                    .Include(t => t.Category)
                    .Include(t => t.Location)
                    .Include(t => t.Images)
                    .Include(t => t.Bids)
                    .FirstAsync(t => t.Id == entity.Id);

                return _mapper.Map<TenderDTO>(saved);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error inserting tender: {Message}", ex.Message);
                throw; 
            }
        }




        public override async Task<TenderDTO> Update(int id, TenderUpdateRequest request)
        {
            _logger.LogInformation("Attempting to update tender with ID {TenderId}", id);

            var tender = await _context.Tenders.FindAsync(id)
                ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });

            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (tender.CreatedByUserId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException(); 
            }

            var state = CreateState(tender.Status);
             return await state.Update(id, request);
        }



        public async Task<TenderDTO> Cancel(int id)
        {
            var entity = await _context.Tenders
                .Include(t => t.Bids) 
                .FirstOrDefaultAsync(t => t.Id == id)
                ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });


            //zadnje dodao provjeru ispod,dosao autentifikacija i autorizacija,4. stavka
            //Šta trebaš popraviti da bi ispunio zahtjev 100%?
//            U kontrolerima: Za operacije tipa "Moji tenderi" ili "Moje ponude", nemoj primati userId kroz parametar metode. Radije napravi metodu bez parametara, a unutar servisa koristi IHttpContextAccessor da dohvatiš ID iz tokena.

//U servisima(Najvažnije): Za svaku Update, Delete ili Cancel metodu, prvo dobavi zapis iz baze, a onda uporedi njegov OwnerId(ili CreatedByUserId) sa ID-em koji dolazi iz tokena.
            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (entity.CreatedByUserId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();
            }

            if (entity.Bids != null && entity.Bids.Any())
            {
                foreach (var bid in entity.Bids)
                {
                   
                    await _bidService.Cancel(bid.Id); 
                }
            }

            var state = CreateState(entity.Status);
            var result = await state.Cancel(id);

            await _context.SaveChangesAsync();

            return result;
        }


        public async Task<TenderDTO> Award(int id, int bidId)
        {
            var tender = await _context.Tenders
        .Include(t => t.Bids)
        .FirstOrDefaultAsync(t => t.Id == id)
        ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });

            var currentUserId = _authService.GetCurrentUserId();
            bool isAdmin = _authService.IsInRole(AppRoles.Admin);

            if (tender.CreatedByUserId != currentUserId && !isAdmin)
            {
                throw new ForbiddenException();
            }

            var state = CreateState(tender.Status);

            var resultDto = await state.Award(tender, bidId);

            await _context.SaveChangesAsync();

            return resultDto;
        }


        public async Task<List<string>> AllowedActions(int id)
        {
            var entity = await _context.Tenders
           .Include(t => t.Bids) 
           .FirstOrDefaultAsync(t => t.Id == id)
                         ?? throw new NotFoundException("Tender not found", new { Entity = "Tender", Id = id });



            var state = CreateState(entity.Status);

            return await state.AllowedActions(entity);
        }

        public async Task<PagedResult<TenderDTO>> SearchAsync(TenderSearchRequest request)
        {
            var query = _context.Tenders
                .AsQueryable();

            query = query.Where(t => t.Status == TenderStatus.Open);

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = $"%{request.SearchTerm.ToLower()}%";

                query = query.Where(t =>
                    EF.Functions.Like(t.Title.ToLower(), term) ||
                     EF.Functions.Like(t.Description.ToLower(), term)
                );
            }

            var totalCount = await query.CountAsync();

            var results = await query
                .ProjectTo<TenderDTO>(_mapper.ConfigurationProvider)
                .ToListAsync();

            return new PagedResult<TenderDTO>
            {
                Result = results,
                TotalCount = totalCount 
            };
        }

       
        public BaseState CreateState(TenderStatus status)
        {
            return status switch
            {
                TenderStatus.Open => _serviceProvider.GetRequiredService<OpenTenderState>(),
                TenderStatus.Closed => _serviceProvider.GetRequiredService<ClosedTenderState>(),
                TenderStatus.Awarded => _serviceProvider.GetRequiredService<AwardedTenderState>(),
                TenderStatus.Cancelled => _serviceProvider.GetRequiredService<CancelledTenderState>(),
                _ => throw new UserException("Invalid tender status")
            };
        }



    }
}
