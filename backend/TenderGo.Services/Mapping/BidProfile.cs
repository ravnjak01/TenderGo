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
    public class BidProfile:Profile
    {
        public BidProfile() {
            CreateMap<Bid, BidDTO>()
    .ForMember(dest => dest.SubmittedByUserName,
               opt => opt.MapFrom(src => src.SubmittedByUser.FirstName + " " + src.SubmittedByUser.LastName));

        }
    }
}
