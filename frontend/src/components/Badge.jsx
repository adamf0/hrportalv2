import React from 'react';
import { CheckCircle2, XCircle, Clock, Calendar, AlertCircle } from 'lucide-react';

export const Badge = ({ status, type, variant, children }) => {
  if (variant) {
    let bg = 'rgba(148, 163, 184, 0.15)';
    let color = '#94a3b8';
    let border = 'rgba(148, 163, 184, 0.3)';

    if (variant === 'success') {
      bg = 'rgba(16, 185, 129, 0.15)';
      color = '#34d399';
      border = 'rgba(16, 185, 129, 0.3)';
    } else if (variant === 'warning') {
      bg = 'rgba(245, 158, 11, 0.15)';
      color = '#fbbf24';
      border = 'rgba(245, 158, 11, 0.3)';
    } else if (variant === 'danger') {
      bg = 'rgba(239, 68, 68, 0.15)';
      color = '#f87171';
      border = 'rgba(239, 68, 68, 0.3)';
    } else if (variant === 'info') {
      bg = 'rgba(6, 182, 212, 0.15)';
      color = '#38bdf8';
      border = 'rgba(6, 182, 212, 0.3)';
    } else if (variant === 'purple') {
      bg = 'rgba(168, 85, 247, 0.15)';
      color = '#c084fc';
      border = 'rgba(168, 85, 247, 0.3)';
    }

    return (
      <span
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '6px',
          padding: '4px 10px',
          borderRadius: '9999px',
          fontSize: '0.75rem',
          fontWeight: 700,
          backgroundColor: bg,
          color: color,
          border: `1px solid ${border}`,
        }}
      >
        {children}
      </span>
    );
  }

  if (!status && !type) return null;

  const rawStatus = (status || type || '').toLowerCase();

  if (rawStatus.includes('terima sdm') || rawStatus === 'disetujui' || rawStatus === 'acc') {
    return (
      <span className="badge badge-success">
        <CheckCircle2 size={13} />
        Disetujui SDM
      </span>
    );
  }

  if (rawStatus.includes('tolak sdm') || rawStatus === 'ditolak') {
    return (
      <span className="badge badge-danger">
        <XCircle size={13} />
        Ditolak SDM
      </span>
    );
  }

  if (rawStatus.includes('terima atasan') || rawStatus === 'disetujui atasan') {
    return (
      <span className="badge badge-info">
        <Clock size={13} />
        Menunggu Verifikasi SDM
      </span>
    );
  }

  if (rawStatus.includes('tolak atasan')) {
    return (
      <span className="badge badge-danger">
        <XCircle size={13} />
        Ditolak Atasan
      </span>
    );
  }

  if (rawStatus.includes('menunggu') || rawStatus === 'pending' || rawStatus === '') {
    return (
      <span className="badge badge-warning">
        <Clock size={13} />
        Menunggu Verifikasi
      </span>
    );
  }

  if (rawStatus.includes('nasional')) {
    return (
      <span className="badge badge-danger">
        <Calendar size={13} />
        Libur Nasional
      </span>
    );
  }

  if (rawStatus.includes('fakultas') || rawStatus.includes('universitas')) {
    return (
      <span className="badge badge-purple">
        <Calendar size={13} />
        Libur Universitas
      </span>
    );
  }

  return (
    <span className="badge badge-info">
      {status || type}
    </span>
  );
};
