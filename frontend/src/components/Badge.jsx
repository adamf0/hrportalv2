import React from 'react';
import { CheckCircle2, XCircle, Clock, AlertCircle, Calendar } from 'lucide-react';

export const Badge = ({ status, type }) => {
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
