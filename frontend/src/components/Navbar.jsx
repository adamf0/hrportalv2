import React from 'react';
import { Menu, ShieldCheck } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const Navbar = ({ onToggleMobileSidebar }) => {
  const { user } = useAuth();

  return (
    <header
      className="navbar-header"
      style={{
        height: '64px',
        backgroundColor: '#ffffff',
        borderBottom: '1px solid var(--border-light)',
        padding: '0 24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        position: 'sticky',
        top: 0,
        zIndex: 50,
        boxShadow: '0 1px 3px rgba(0,0,0,0.02)',
      }}
    >
      {/* Left: Mobile hamburger menu toggle */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <button
          onClick={onToggleMobileSidebar}
          className="mobile-menu-toggle-btn"
          style={{
            background: '#f1f5f9',
            border: '1px solid var(--border-light)',
            borderRadius: '8px',
            padding: '8px',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'var(--text-main)',
          }}
          title="Toggle Menu"
        >
          <Menu size={20} />
        </button>
      </div>

      {/* Right: SDM Badge & User Pill */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
        <div
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '6px',
            background: 'var(--color-primary-50)',
            padding: '5px 12px',
            borderRadius: '9999px',
            border: '1px solid var(--color-primary-100)',
          }}
        >
          <ShieldCheck size={15} color="var(--color-primary)" />
          <span style={{ fontSize: '0.775rem', fontWeight: 700, color: 'var(--color-primary)' }}>
            Panel SDM
          </span>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <div
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '50%',
              background: 'linear-gradient(135deg, #6b21a8 0%, #a855f7 100%)',
              color: 'white',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 800,
              fontSize: '0.8rem',
            }}
          >
            {(user?.name || user?.preferred_username || 'S')[0].toUpperCase()}
          </div>
          <span style={{ fontSize: '0.825rem', fontWeight: 700, color: 'var(--text-main)' }} className="hide-on-mobile">
            {user?.name || user?.preferred_username || 'SDM'}
          </span>
        </div>
      </div>
    </header>
  );
};
