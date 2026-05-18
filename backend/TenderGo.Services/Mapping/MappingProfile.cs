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
    public class MappingProfile:Profile
    {
        public MappingProfile()
        {


            CreateMap<Category, CategoryDTO>().ReverseMap();
            CreateMap<CategoryUpdateRequest, Category>();

            CreateMap<LocationInsertRequest, Location>()
                .ForMember(d => d.Name, o => o.MapFrom(s => s.City ?? string.Empty));
            CreateMap<LocationUpdateRequest, Location>();

        }
    }
}
