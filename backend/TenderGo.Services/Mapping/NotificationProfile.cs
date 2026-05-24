using AutoMapper;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;

namespace TenderGo.Services.Mapping
{
    
        public class NotificationProfile : Profile
        {
            public NotificationProfile()
            {
                // Mapiranje iz Entiteta (Baza) u DTO (Frontend)
                CreateMap<Notification, NotificationDTO>()
                    // Pošto 'Type' ne postoji u entitetu, postavljamo mu defaultnu vrijednost iz DTO-a ("general")
                    .ForMember(dest => dest.Type, opt => opt.MapFrom(src => "general"))
                    // Pošto 'TenderId' ne postoji u entitetu, za sada ga ignorišemo ili stavljamo null
                    .ForMember(dest => dest.TenderId, opt => opt.Ignore());

                CreateMap<NotificationDTO, Notification>()
                    .ForMember(dest => dest.User, opt => opt.Ignore()) 
                    .ForMember(dest => dest.UserId, opt => opt.Ignore()); 
            }
        }
    
}