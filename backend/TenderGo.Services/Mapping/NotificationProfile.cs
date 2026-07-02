using AutoMapper;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;

namespace TenderGo.Services.Mapping
{
    
        public class NotificationProfile : Profile
        {
            public NotificationProfile()
            {
                CreateMap<Notification, NotificationDTO>()
                    .ForMember(dest => dest.Type, opt => opt.MapFrom(src => "general"))
                    .ForMember(dest => dest.TenderId, opt => opt.Ignore());

                CreateMap<NotificationDTO, Notification>()
                    .ForMember(dest => dest.User, opt => opt.Ignore()) 
                    .ForMember(dest => dest.UserId, opt => opt.Ignore()); 
            }
        }
    
}