import React from 'react';
import { 
  LayoutDashboard, 
  CalendarDays, 
  FileCheck, 
  CalendarClock, 
  PlaneTakeoff, 
  FileSpreadsheet,
  LogOut, 
  Building2,
  X
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const Sidebar = ({ activeTab, onSelectTab, isCollapsed, onToggleCollapse, isMobileOpen, onCloseMobile }) => {
  const { user, logout } = useAuth();

  const menuItems = [
    { id: 'dashboard', label: 'Dashboard SDM', icon: LayoutDashboard },
    { id: 'libur', label: 'Master Libur', icon: CalendarDays },
    { id: 'izin', label: 'Verifikasi Izin', icon: FileCheck },
    { id: 'cuti', label: 'Verifikasi Cuti', icon: CalendarClock },
    { id: 'sppd', label: 'Verifikasi SPPD', icon: PlaneTakeoff },
    { id: 'laporan', label: 'Laporan Presensi', icon: FileSpreadsheet },
  ];

  return (
    <>
      {/* Mobile Backdrop */}
      {isMobileOpen && (
        <div
          onClick={onCloseMobile}
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0, 0, 0, 0.5)',
            backdropFilter: 'blur(4px)',
            zIndex: 999,
          }}
          className="mobile-sidebar-backdrop"
        />
      )}

      <aside
        className={`sidebar-container ${isMobileOpen ? 'mobile-open' : ''}`}
        style={{
          width: isCollapsed ? '80px' : '260px',
          backgroundColor: '#1e1b4b',
          color: '#ffffff',
          display: 'flex',
          flexDirection: 'column',
          transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
          borderRight: '1px solid rgba(255, 255, 255, 0.1)',
          height: '100vh',
          position: 'fixed',
          top: 0,
          left: 0,
          zIndex: 1000,
        }}
      >
        {/* Brand Header */}
        <div
          style={{
            padding: '20px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            borderBottom: '1px solid rgba(255, 255, 255, 0.08)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              style={{
                width: '38px',
                height: '38px',
                borderRadius: '10px',
                background: 'linear-gradient(135deg, #a855f7 0%, #6b21a8 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                boxShadow: '0 4px 12px rgba(168, 85, 247, 0.35)',
                flexShrink: 0,
              }}
            >
              <Building2 size={20} color="#ffffff" />
            </div>
            {!isCollapsed && (
              <div>
                <div style={{ fontWeight: 800, fontSize: '1.02rem', letterSpacing: '-0.02em', color: '#f8fafc' }}>
                  HR Portal <span style={{ color: '#c084fc', fontSize: '0.825rem', fontWeight: 600 }}>SDM</span>
                </div>
                <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>Universitas Pakuan</div>
              </div>
            )}
          </div>

          {/* Close button on mobile */}
          <button
            onClick={onCloseMobile}
            className="mobile-close-btn"
            style={{
              background: 'transparent',
              border: 'none',
              color: '#94a3b8',
              cursor: 'pointer',
              display: 'none',
              padding: '4px',
            }}
          >
            <X size={20} />
          </button>
        </div>

        {/* Navigation List */}
        <nav style={{ flex: 1, padding: '16px 12px', display: 'flex', flexDirection: 'column', gap: '6px', overflowY: 'auto' }}>
          <div style={{ fontSize: '0.68rem', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.08em', padding: '0 12px 6px 12px' }}>
            {!isCollapsed && 'Menu Utama'}
          </div>

          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => {
                  onSelectTab(item.id);
                  if (onCloseMobile) onCloseMobile();
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '12px',
                  width: '100%',
                  padding: '11px 14px',
                  borderRadius: '10px',
                  border: 'none',
                  background: isActive
                    ? 'linear-gradient(135deg, rgba(168, 85, 247, 0.25) 0%, rgba(107, 33, 168, 0.4) 100%)'
                    : 'transparent',
                  color: isActive ? '#f8fafc' : '#94a3b8',
                  fontWeight: isActive ? 700 : 500,
                  fontSize: '0.875rem',
                  cursor: 'pointer',
                  transition: 'all 0.15s',
                  position: 'relative',
                  textAlign: 'left',
                }}
              >
                {isActive && (
                  <div
                    style={{
                      position: 'absolute',
                      left: 0,
                      top: '25%',
                      bottom: '25%',
                      width: '4px',
                      borderRadius: '0 4px 4px 0',
                      backgroundColor: 'var(--color-primary)',
                    }}
                  />
                )}
                <Icon size={19} color={isActive ? '#c084fc' : '#94a3b8'} style={{ flexShrink: 0 }} />
                {!isCollapsed && <span>{item.label}</span>}
              </button>
            );
          })}
        </nav>

        {/* User Profile & Logout */}
        <div
          style={{
            padding: '16px',
            borderTop: '1px solid rgba(255, 255, 255, 0.08)',
            display: 'flex',
            flexDirection: 'column',
            gap: '12px',
          }}
        >
          {!isCollapsed && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '0 4px' }}>
              <div
                style={{
                  width: '34px',
                  height: '34px',
                  borderRadius: '50%',
                  background: '#312e81',
                  color: '#c084fc',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 800,
                  fontSize: '0.85rem',
                }}
              >
                {(user?.name || user?.preferred_username || 'S')[0].toUpperCase()}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: '0.825rem', fontWeight: 700, color: '#f8fafc', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {user?.name || user?.preferred_username || 'Admin SDM'}
                </div>
                <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>
                  {user?.level?.toUpperCase() || 'SDM'}
                </div>
              </div>
            </div>
          )}

          <button
            onClick={logout}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: isCollapsed ? 'center' : 'flex-start',
              gap: '10px',
              width: '100%',
              padding: '10px 12px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: 'rgba(239, 68, 68, 0.1)',
              color: '#f87171',
              fontWeight: 600,
              fontSize: '0.825rem',
              cursor: 'pointer',
              transition: 'background 0.15s',
            }}
          >
            <LogOut size={16} />
            {!isCollapsed && <span>Keluar Aplikasi</span>}
          </button>
        </div>
      </aside>
    </>
  );
};
