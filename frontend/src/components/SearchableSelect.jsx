import React, { useState, useRef, useEffect } from 'react';
import { Search, ChevronDown, Check, X } from 'lucide-react';

export const SearchableSelect = ({
  options = [],
  value,
  onChange,
  placeholder = 'Pilih...',
  searchPlaceholder = 'Cari...',
  renderOption,
  renderSelected,
  disabled = false,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const containerRef = useRef(null);

  // Close dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const selectedOption = options.find((opt) => String(opt.value) === String(value));

  const filteredOptions = options.filter((opt) => {
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    const label = (opt.label || opt.name || opt.nama || '').toLowerCase();
    const val = String(opt.value || '').toLowerCase();
    const desc = (opt.desc || opt.subtitle || opt.nip || opt.jabatan || '').toLowerCase();
    return label.includes(q) || val.includes(q) || desc.includes(q);
  });

  return (
    <div ref={containerRef} style={{ position: 'relative', width: '100%' }}>
      {/* Trigger Field */}
      <div
        onClick={() => !disabled && setIsOpen(!isOpen)}
        className="bm-input"
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          cursor: disabled ? 'not-allowed' : 'pointer',
          background: disabled ? '#f3f4f6' : '#ffffff',
          borderColor: isOpen ? '#10b981' : '#e2e8f0',
          boxShadow: isOpen ? '0 0 0 3px rgba(16, 185, 129, 0.15)' : 'none',
          padding: '10px 14px',
          minHeight: '42px',
          borderRadius: '10px',
        }}
      >
        <div style={{ flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {selectedOption ? (
            renderSelected ? (
              renderSelected(selectedOption)
            ) : (
              <span style={{ fontWeight: 700, color: '#0f172a' }}>{selectedOption.label || selectedOption.name}</span>
            )
          ) : (
            <span style={{ color: '#94a3b8' }}>{placeholder}</span>
          )}
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#64748b' }}>
          {selectedOption && !disabled && (
            <button
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                onChange(null);
              }}
              style={{ background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer', padding: '2px' }}
            >
              <X size={14} />
            </button>
          )}
          <ChevronDown size={16} style={{ transition: 'transform 0.2s ease', transform: isOpen ? 'rotate(180deg)' : 'rotate(0)' }} />
        </div>
      </div>

      {/* Searchable Dropdown Popup */}
      {isOpen && (
        <div
          style={{
            position: 'absolute',
            top: 'calc(100% + 6px)',
            left: 0,
            right: 0,
            zIndex: 9999,
            background: '#ffffff',
            border: '1px solid #e2e8f0',
            borderRadius: '14px',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
            overflow: 'hidden',
            animation: 'fadeIn 0.2s ease forwards',
          }}
        >
          {/* Search Box Input */}
          <div style={{ padding: '10px 12px', borderBottom: '1px solid #f1f5f9', position: 'relative' }}>
            <Search size={15} color="#94a3b8" style={{ position: 'absolute', left: '20px', top: '50%', transform: 'translateY(-50%)' }} />
            <input
              type="text"
              autoFocus
              className="bm-input"
              placeholder={searchPlaceholder}
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{
                paddingLeft: '36px',
                height: '36px',
                fontSize: '0.85rem',
                borderRadius: '8px',
                background: '#f8fafc',
              }}
            />
          </div>

          {/* Options List */}
          <div style={{ maxHeight: '220px', overflowY: 'auto', padding: '4px' }}>
            {filteredOptions.length === 0 ? (
              <div style={{ padding: '16px', textAlign: 'center', color: '#94a3b8', fontSize: '0.825rem' }}>
                Tidak ada opsi ditemukan.
              </div>
            ) : (
              filteredOptions.map((opt) => {
                const isSelected = String(opt.value) === String(value);
                return (
                  <div
                    key={opt.value}
                    onClick={() => {
                      onChange(opt.value, opt);
                      setIsOpen(false);
                      setSearchQuery('');
                    }}
                    style={{
                      padding: '10px 14px',
                      borderRadius: '8px',
                      cursor: 'pointer',
                      background: isSelected ? '#f0fdf4' : 'transparent',
                      color: isSelected ? '#15803d' : '#0f172a',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      transition: 'background 0.15s ease',
                      marginBottom: '2px',
                    }}
                    onMouseEnter={(e) => {
                      if (!isSelected) e.currentTarget.style.background = '#f8fafc';
                    }}
                    onMouseLeave={(e) => {
                      if (!isSelected) e.currentTarget.style.background = 'transparent';
                    }}
                  >
                    <div style={{ flex: 1 }}>
                      {renderOption ? (
                        renderOption(opt)
                      ) : (
                        <div>
                          <div style={{ fontWeight: 700, fontSize: '0.875rem' }}>{opt.label || opt.name}</div>
                          {opt.subtitle && <div style={{ fontSize: '0.75rem', color: '#64748b' }}>{opt.subtitle}</div>}
                        </div>
                      )}
                    </div>
                    {isSelected && <Check size={16} color="#10b981" />}
                  </div>
                );
              })
            )}
          </div>
        </div>
      )}
    </div>
  );
};
