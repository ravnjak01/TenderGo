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
            CreateMap<Tender, TenderDTO>()
                    .IncludeBase<Tender, AdminTenderDTO>()
                    .ForMember(dest => dest.CategoryName,
                               opt => opt.MapFrom(src => src.Category != null ? src.Category.Name : string.Empty))
                    .ForMember(dest => dest.TotalBids,
                               opt => opt.MapFrom(src => src.Bids != null ? src.Bids.Count : 0));

            CreateMap<Tender, AdminTenderDTO>()
              .ForMember(dest => dest.CreatedByUserFullName,
                         opt => opt.MapFrom(src => src.CreatedByUser != null
                             ? $"{src.CreatedByUser.FirstName} {src.CreatedByUser.LastName}"
                             : string.Empty));

            CreateMap<TenderInsertRequest, Tender>()
                .ForMember(dest => dest.Images, opt => opt.Ignore());


            CreateMap<TenderImage, TenderImageDTO>();

            CreateMap<Location, LocationDTO>();
        }
    }
}
