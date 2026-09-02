import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

export const Pagination = ({
  currentPage = 1,
  totalItems = 0,
  itemsPerPage = 10,
  onPageChange,
  onItemsPerPageChange,
  itemsPerPageOptions = [10, 25, 50, 100],
}) => {
  const totalPages = Math.max(1, Math.ceil(totalItems / itemsPerPage));
  const startItem = totalItems === 0 ? 0 : (currentPage - 1) * itemsPerPage + 1;
  const endItem = Math.min(totalItems, currentPage * itemsPerPage);

  const getPageNumbers = () => {
    const pages = [];
    if (totalPages <= 7) {
      for (let i = 1; i <= totalPages; i++) pages.push(i);
    } else {
      if (currentPage <= 4) {
        pages.push(1, 2, 3, 4, 5, '...', totalPages);
      } else if (currentPage >= totalPages - 3) {
        pages.push(1, '...', totalPages - 4, totalPages - 3, totalPages - 2, totalPages - 1, totalPages);
      } else {
        pages.push(1, '...', currentPage - 1, currentPage, currentPage + 1, '...', totalPages);
      }
    }
    return pages;
  };

  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        flexWrap: 'wrap',
        gap: '16px',
        padding: '16px 20px',
        borderTop: '1px solid #e2e8f0',
        background: '#ffffff',
        borderBottomLeftRadius: '12px',
        borderBottomRightRadius: '12px',
      }}
    >
      {/* Summary & Page Size Selector */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px', fontSize: '0.85rem', color: '#64748b' }}>
        <span>
          Menampilkan <strong style={{ color: '#0f172a', fontWeight: 800 }}>{startItem}</strong>–
          <strong style={{ color: '#0f172a', fontWeight: 800 }}>{endItem}</strong> dari{' '}
          <strong style={{ color: '#0f172a', fontWeight: 800 }}>{totalItems}</strong> data
        </span>

        {onItemsPerPageChange && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '0.8rem', color: '#64748b' }}>Baris per halaman:</span>
            <select
              value={itemsPerPage}
              onChange={(e) => onItemsPerPageChange(Number(e.target.value))}
              style={{
                padding: '4px 10px',
                fontSize: '0.8rem',
                fontWeight: 700,
                color: '#0f172a',
                background: '#ffffff',
                border: '1px solid #cbd5e1',
                borderRadius: '6px',
                outline: 'none',
                cursor: 'pointer',
                boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
              }}
            >
              {itemsPerPageOptions.map((opt) => (
                <option key={opt} value={opt}>
                  {opt}
                </option>
              ))}
            </select>
          </div>
        )}
      </div>

      {/* Navigation Buttons */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
        <button
          type="button"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage <= 1}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '32px',
            height: '32px',
            borderRadius: '6px',
            border: '1px solid #e2e8f0',
            background: currentPage <= 1 ? '#f8fafc' : '#ffffff',
            color: currentPage <= 1 ? '#cbd5e1' : '#334155',
            cursor: currentPage <= 1 ? 'not-allowed' : 'pointer',
            transition: 'all 0.15s ease',
          }}
          title="Halaman Sebelumnya"
        >
          <ChevronLeft size={16} />
        </button>

        {getPageNumbers().map((p, idx) => {
          if (p === '...') {
            return (
              <span key={`dots-${idx}`} style={{ padding: '0 4px', color: '#94a3b8', fontSize: '0.85rem' }}>
                ...
              </span>
            );
          }

          const isActive = p === currentPage;
          return (
            <button
              key={p}
              type="button"
              onClick={() => onPageChange(p)}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                minWidth: '32px',
                height: '32px',
                padding: '0 8px',
                borderRadius: '6px',
                border: isActive ? '1px solid #10b981' : '1px solid #e2e8f0',
                background: isActive ? '#10b981' : '#ffffff',
                color: isActive ? '#ffffff' : '#334155',
                fontWeight: isActive ? 800 : 600,
                fontSize: '0.85rem',
                cursor: 'pointer',
                boxShadow: isActive ? '0 2px 4px rgba(16, 185, 129, 0.25)' : 'none',
                transition: 'all 0.15s ease',
              }}
            >
              {p}
            </button>
          );
        })}

        <button
          type="button"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage >= totalPages}
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: '32px',
            height: '32px',
            borderRadius: '6px',
            border: '1px solid #e2e8f0',
            background: currentPage >= totalPages ? '#f8fafc' : '#ffffff',
            color: currentPage >= totalPages ? '#cbd5e1' : '#334155',
            cursor: currentPage >= totalPages ? 'not-allowed' : 'pointer',
            transition: 'all 0.15s ease',
          }}
          title="Halaman Berikutnya"
        >
          <ChevronRight size={16} />
        </button>
      </div>
    </div>
  );
};
