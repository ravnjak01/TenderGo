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
using TenderGo.Models.DTOs;
using TenderGo.Models.Requests;
using TenderGo.Services.Interfaces;
using TenderGo.Services.Services.Exceptions;

namespace TenderGo.Services.Services
{
    public class BaseService<TModel, TDb, TSearch, TInsert, TUpdate>
        : IReadService<TModel, TSearch>, IWriteService<TModel, TInsert, TUpdate>
           where TModel : class
        where TDb : class
        where TSearch : PagedSearchRequest
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

      
        protected virtual IQueryable<TDb> ApplyFilter(IQueryable<TDb> query, TSearch request)
        {
            return query;

        }
        protected virtual IQueryable<TDb> ApplySorting(IQueryable<TDb> query)
        {
            return query.OrderByDescending(e => EF.Property<int>(e, "Id"));
        }
        protected virtual IQueryable<TDb> AddIncludes(IQueryable<TDb> query) => query;

        public virtual async Task<TModel> GetById(int id)
        {
            var query = _context.Set<TDb>().AsQueryable();

            query = AddIncludes(query);

            var entity = await query.FirstOrDefaultAsync(e => EF.Property<int>(e, "Id") == id)
                 ?? throw new UserException($"{typeof(TDb).Name} not found");

            return _mapper.Map<TModel>(entity);
        }

        public async Task<PagedResult<TModel>> Get(TSearch request)
        {
            var query = _context.Set<TDb>().AsQueryable();

            query = AddIncludes(query);
            query = ApplyFilter(query,request);
            query=ApplySorting(query);
            const int maxPageSize = 100;

            int page = request.Page <= 0 ? 1 : request.Page;
            int pageSize = request.PageSize <= 0 ? 10 : request.PageSize;

            if (pageSize > maxPageSize)
            {
                pageSize = maxPageSize; 
            }

            var totalCount = await query.CountAsync();
            var list = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<TModel>
            {
                Result = _mapper.Map<List<TModel>>(list),
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }


        
        
        public virtual async Task<TModel> Insert(TInsert request)
        {
            var entity = _mapper.Map<TDb>(request);
            _context.Set<TDb>().Add(entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<TModel>(entity);
        }
        public virtual async Task<TModel> Update(int id, TUpdate request)
        {
            var entity = await _context.Set<TDb>().FindAsync(id)
                 ?? throw new UserException($"{typeof(TDb).Name} not found");

            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<TModel>(entity);
        }

        public virtual async Task<string> Delete(int id)
        {
            var entity = await _context.Set<TDb>().FindAsync(id)
     ?? throw new UserException($"{typeof(TDb).Name} not found");

            _context.Set<TDb>().Remove(entity);
            await _context.SaveChangesAsync();
            return $"{typeof(TDb).Name} deleted successfully.";
        }

       
    }
}
