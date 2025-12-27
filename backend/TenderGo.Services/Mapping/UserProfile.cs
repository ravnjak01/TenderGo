using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.Entities;
using TenderGo.Services.DTOs;

namespace TenderGo.Services.Mapping
{
    public class UserProfile:Profile
    {

        public UserProfile()
        {
     CreateMap<RegisterDTO,ApplicationUser>()
            .ForMember(dest => dest.UserName,
               opt => opt.MapFrom(src => src.Email));

        }
    }
}
