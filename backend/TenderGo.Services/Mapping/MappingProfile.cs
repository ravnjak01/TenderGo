using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;

namespace TenderGo.Services.Mapping
{
    public class MappingProfile:Profile
    {
        public MappingProfile()
        {
            // Add your object-object mapping configurations here
            //CreateMap<Class, Destination>();

            CreateMap<Category, CategoryDTO>().ReverseMap();
        }
    }
}
