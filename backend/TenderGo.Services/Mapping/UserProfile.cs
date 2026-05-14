using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Mapping
{
    public class UserProfile:Profile
    {

        public UserProfile()
        {
            CreateMap<RegisterRequest, ApplicationUser>()
             .ForMember(dest => dest.UserName, opt => opt.MapFrom(src => src.Email));

            CreateMap<ApplicationUser, UserDTO>()
             .ForMember(dest => dest.Roles, opt => opt.Ignore());

            CreateMap<UpdateProfileRequest, ApplicationUser>()
                .ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));

            CreateMap<Address, AddressDTO>().ReverseMap();

            CreateMap<ApplicationUser, UserPublicDTO>()
        .ForMember(dest => dest.Location, opt => opt.MapFrom(src =>
            src.Address != null ? $"{src.Address.City}, {src.Address.Country}" : null))
        .ForMember(dest => dest.TenderCount, opt => opt.MapFrom(src =>
            src.CreatedTenders != null ? src.CreatedTenders.Count : 0))
        .ForMember(dest => dest.BidsCount, opt => opt.Ignore());

            CreateMap<UpdateAddressRequest, Address>()
    .ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));

            CreateMap<UpdateProfileRequest, ApplicationUser>()
                .ForMember(dest => dest.FirstName, opt => opt.Ignore())
                .ForMember(dest => dest.LastName, opt => opt.Ignore())
                .ForMember(dest => dest.ProfileImageUrl, opt => opt.Ignore())
                .ForMember(dest => dest.Address, opt => opt.Condition(src => src.Address != null));
        }
    }
}
