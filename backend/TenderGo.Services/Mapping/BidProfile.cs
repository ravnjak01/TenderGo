using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Models.DTOs;
using TenderGo.Models.Entities;
using TenderGo.Models.ENUMs;
using TenderGo.Models.Requests;

namespace TenderGo.Services.Mapping
{
    public class BidProfile:Profile
    {
        public BidProfile() {
            CreateMap<Bid, BidDTO>()
    .ForMember(dest => dest.SubmittedByUserName,
               opt => opt.MapFrom(src => src.SubmittedByUser.FirstName + " " + src.SubmittedByUser.LastName));


            CreateMap<BidInsertRequest, Bid>()
                .ForMember(dest => dest.OfferedPrice, opt => opt.MapFrom(src => src.Price))
                .ForMember(dest => dest.Proposal, opt => opt.MapFrom(src => src.Note))
                .ForMember(dest => dest.SubmittedByUserId, opt => opt.MapFrom(src => src.UserId.ToString()))
                .ForMember(dest => dest.Status, opt => opt.MapFrom(src => ApplicationStatus.Pending))
                .ForMember(dest => dest.SubmittedAt, opt => opt.MapFrom(src => DateTime.UtcNow));
        }
    }
}
