using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions; // Ovdje ti se nalazi UserException

namespace TenderGo.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly TenderGoContext _context;
        private readonly IMapper _mapper;
        private readonly IHttpContextAccessor _httpContextAccessor;

        // Konstruktor bez : base(...), polja se dodjeljuju direktno
        public NotificationService(TenderGoContext context, IMapper mapper, IHttpContextAccessor httpContextAccessor) 
        {
            _context = context;
            _mapper = mapper;
            _httpContextAccessor = httpContextAccessor;
        }

        // 1. Dobavi sve notifikacije za ulogovanog korisnika (poredano od najnovijih)
        public async Task<List<NotificationDTO>> GetMyNotificationsAsync(string userId)
        {
            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();

            return _mapper.Map<List<NotificationDTO>>(notifications);
        }

        // 2. Označi pojedinačnu notifikaciju kao pročitanu (uz provjeru vlasništva zbog sigurnosti)
        public async Task<NotificationDTO> MarkAsReadAsync(int id, string userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId)
                ?? throw new UserException("Notifikacija nije pronađena.");

            notification.IsRead = true;
            await _context.SaveChangesAsync();

            return _mapper.Map<NotificationDTO>(notification);
        }

        // 3. Označi sve nepročitane notifikacije korisnika kao pročitane
        public async Task MarkAllAsReadAsync(string userId)
        {
            var unreadNotifications = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            if (!unreadNotifications.Any()) return;

            foreach (var notification in unreadNotifications)
            {
                notification.IsRead = true;
            }

            await _context.SaveChangesAsync();
        }

        // 4. Obriši notifikaciju (uz provjeru vlasništva)
        public async Task DeleteAsync(int id, string userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId)
                ?? throw new UserException("Notifikacija nije pronađena.");

            _context.Notifications.Remove(notification);
            await _context.SaveChangesAsync();
        }
    }
}