using AutoMapper;
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
    public class BaseService<T,TDb> : IBaseService<T> where TDb : class where T : class
    {

        TenderGoContext _context;
        IMapper _mapper;
        public BaseService(TenderGoContext context,IMapper mapper) {

            _context = context;
            _mapper = mapper;

        }

        public async Task<IEnumerable<T>>Get()
        {
            var query = _context.Set<TDb>().AsQueryable();
            var list =await query.ToListAsync();

            return _mapper.Map<List<T>>(list);
        }

        public async Task<T?>GetById(int id)
        {
            var entity=await _context.Set<TDb>().FindAsync(id);
            return _mapper.Map<T?>(entity);
        }
        public async Task<T> Insert(TenderInsertRequest request)
        {
            var entity = _mapper.Map<TDb>(request);
            _context.Set<TDb>().Add(entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<T>(entity);
        }
        public async Task<T?> Update(int id, TenderUpdateRequest request)
        {
            var entity = await _context.Set<TDb>().FindAsync(id);
            if (entity == null)
                return null;
            _mapper.Map(request, entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<T>(entity);
        }

        public async Task<bool> Delete(int id)
        {
            var entity = await _context.Set<TDb>().FindAsync(id);
            if (entity == null)
                return false;
            _context.Set<TDb>().Remove(entity);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
