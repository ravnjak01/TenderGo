using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Mapping
{
    public class TenderProfile:Profile
    {
        public TenderProfile()
        {
            CreateMap<Tender, TenderDTO>();
            CreateMap<TenderInsertRequest, Tender>();
            CreateMap<TenderUpdateRequest, Tender>();
            CreateMap<Tender, TenderDTO>()
                 .ForMember(dest => dest.CreatedByFullname,
               opt => opt.MapFrom(src => src.CreatedByUser.FirstName + " " + src.CreatedByUser.LastName));

        }
    }
}
