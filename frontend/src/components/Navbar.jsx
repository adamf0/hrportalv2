import React from 'react';
import { Menu, Search, ShieldCheck, ChevronRight } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const Navbar = ({ onToggleMobileSidebar, activeTab = 'dashboard', periodType = 'cutoff', onPeriodTypeChange }) => {
  const { user, userRole, availableRoles, canSwitchRole, switchRole } = useAuth();

  const getPageTitle = () => {
    switch (activeTab) {
      case 'dashboard': return 'Dashboard Overview & Presensi';
      case 'cuti': return 'Pengajuan Cuti';
      case 'izin': return 'Pengajuan Izin';
      case 'sppd': return 'Pengajuan SPPD';
      case 'slip-gaji': return 'Slip Gaji Pegawai';
      case 'libur': return 'Master Libur';
      case 'laporan': return 'Laporan Presensi';
      default: return 'HR Portal';
    }
  };

  const showPeriodToggle = activeTab === 'dashboard' || activeTab === 'laporan';

  return (
    <header className="navbar-header">
      {/* Left: Breadcrumbs & Mobile Toggle */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px', minWidth: 0, flexShrink: 1 }}>
        <button
          onClick={onToggleMobileSidebar}
          style={{
            background: '#f9fafb',
            border: '1px solid #e5e7eb',
            borderRadius: '6px',
            padding: '6px',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            color: '#111827',
            flexShrink: 0,
          }}
          title="Toggle Sidebar"
        >
          <Menu size={18} />
        </button>

        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.825rem', overflow: 'hidden' }}>
          <span className="navbar-title-sub" style={{ color: '#6b7280', fontWeight: 500, whiteSpace: 'nowrap' }}>HR Portal UNPAK</span>
          <ChevronRight size={14} color="#9ca3af" className="navbar-title-sub" style={{ flexShrink: 0 }} />
          <span className="navbar-page-title" style={{ color: '#111827', fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {getPageTitle()}
          </span>
        </div>
      </div>

      {/* Right: PERIODE SWITCHER & ROLE SWITCHER */}
      <div className="navbar-right-container" style={{ display: 'flex', alignItems: 'center', gap: '8px', flexShrink: 0 }}>
        {showPeriodToggle && (
          <div style={{ display: 'flex', background: '#f3f4f6', padding: '3px', borderRadius: '10px', border: '1px solid #e5e7eb' }}>
            <button
              type="button"
              onClick={() => onPeriodTypeChange && onPeriodTypeChange('cutoff')}
              className="navbar-period-btn"
              style={{
                padding: '4px 10px',
                borderRadius: '7px',
                border: 'none',
                background: periodType === 'cutoff' ? '#ffffff' : 'transparent',
                color: periodType === 'cutoff' ? '#111827' : '#6b7280',
                fontWeight: periodType === 'cutoff' ? 800 : 500,
                fontSize: '0.75rem',
                cursor: 'pointer',
                boxShadow: periodType === 'cutoff' ? '0 1px 3px rgba(0,0,0,0.1)' : 'none',
                transition: 'all 0.15s ease',
                whiteSpace: 'nowrap',
              }}
            >
              Cutoff 16-15
            </button>
            <button
              type="button"
              onClick={() => onPeriodTypeChange && onPeriodTypeChange('calendar')}
              className="navbar-period-btn"
              style={{
                padding: '4px 10px',
                borderRadius: '7px',
                border: 'none',
                background: periodType === 'calendar' ? '#ffffff' : 'transparent',
                color: periodType === 'calendar' ? '#111827' : '#6b7280',
                fontWeight: periodType === 'calendar' ? 800 : 500,
                fontSize: '0.75rem',
                cursor: 'pointer',
                boxShadow: periodType === 'calendar' ? '0 1px 3px rgba(0,0,0,0.1)' : 'none',
                transition: 'all 0.15s ease',
                whiteSpace: 'nowrap',
              }}
            >
              Bulan 01-31
            </button>
          </div>
        )}

        {/* ROLE SWITCHER ACTION (DYNAMICAL FROM LOCALSTORAGE USER GROUPS) */}
        {canSwitchRole && availableRoles && availableRoles.length > 1 && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', background: '#f8fafc', padding: '3px 8px', borderRadius: '10px', border: '1px solid #cbd5e1' }}>
            <span className="navbar-switch-label" style={{ fontSize: '0.7rem', fontWeight: 800, color: '#475569', textTransform: 'uppercase', whiteSpace: 'nowrap' }}>
              Switch Role:
            </span>
            <select
              value={userRole}
              onChange={(e) => switchRole(e.target.value)}
              style={{
                background: '#ffffff',
                border: '1px solid #94a3b8',
                borderRadius: '6px',
                padding: '3px 6px',
                fontSize: '0.75rem',
                fontWeight: 800,
                color: '#0f172a',
                cursor: 'pointer',
                outline: 'none',
                boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
              }}
              title="Ganti Role Akses Berdasarkan User Groups"
            >
              {availableRoles.map((r) => (
                <option key={r} value={r}>
                  {r.toUpperCase()}
                </option>
              ))}
            </select>
          </div>
        )}
      </div>
    </header>
  );
};
