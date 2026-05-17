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
            .ForMember(dest => dest.CreatedByFullname, opt => opt.MapFrom(src =>
                src.CreatedByUser != null
                ? $"{src.CreatedByUser.FirstName} {src.CreatedByUser.LastName}"
                : "Unknown author"))
            .ForMember(dest => dest.CategoryName, opt => opt.MapFrom(src =>
                  src.Category != null ? src.Category.Name : string.Empty))
            .ForMember(dest => dest.TotalBids, opt => opt.MapFrom(src =>
                    src.Bids.Count))
            .ForMember(dest => dest.Images, opt => opt.MapFrom(src =>
                 src.Images));

            CreateMap<TenderInsertRequest, Tender>()
                .ForMember(dest => dest.Images, opt => opt.Ignore());



            CreateMap<TenderUpdateRequest, Tender>()
                .ForAllMembers(opts => opts.Condition((src, dest, srcMember) => srcMember != null));

            CreateMap<TenderImage, TenderImageDTO>();

            CreateMap<Location, LocationDTO>();
        }
    }
}
