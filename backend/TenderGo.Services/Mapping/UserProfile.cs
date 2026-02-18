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
                   .ForMember(dest => dest.Email,
                      opt => opt.MapFrom(src => src.Email))
                   .ForMember(dest => dest.UserName,
                      opt => opt.MapFrom(src => src.Email));

            CreateMap<ApplicationUser, MeResponseDTO>()
           .ForMember(dest => dest.Roles, opt => opt.Ignore());
        }
    }
}
