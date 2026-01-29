using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TenderGo.Api.Database;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;

namespace TenderGo.Services.Services
{
    public class BaseService<T,TDb,TInsert,TUpdate> : IBaseService<T,TDb,TInsert,TUpdate> where TDb : class where T : class
    {

       protected readonly TenderGoContext _context;
       protected  readonly IMapper _mapper;
        protected readonly IHttpContextAccessor _httpContextAccessor;
        public BaseService(TenderGoContext context,IMapper mapper, IHttpContextAccessor httpContextAccessor)
        {

            _context = context;
            _mapper = mapper;
            _httpContextAccessor = httpContextAccessor;
        }

        public async Task<IEnumerable<T>>Get()
        {
            var query = _context.Set<TDb>();
            var list =await query.ToListAsync();

            return _mapper.Map<IEnumerable<T>>(list);
        }

        public async Task<T?>GetById(int id)
        {
            var entity = await _context.Set<TDb>().FindAsync(id)
      ?? throw new UserException($"{typeof(TDb).Name} not found");

            return _mapper.Map<T>(entity);


        }
        public virtual async Task<T> Insert(TInsert request)
        {
            var entity = _mapper.Map<TDb>(request);
            _context.Set<TDb>().Add(entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<T>(entity);
        }
        public virtual async Task Update(int id, TUpdate request)
        {
            var entity = await _context.Set<TDb>().FindAsync(id)
       ?? throw new UserException($"{typeof(TDb).Name} not found");

            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();
        }

        public async Task Delete(int id)
        {
            var entity = await _context.Set<TDb>().FindAsync(id)
     ?? throw new UserException($"{typeof(TDb).Name} not found");

            _context.Set<TDb>().Remove(entity);
            await _context.SaveChangesAsync();
        }

       
    }
}
