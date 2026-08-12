import React, { useState, useEffect } from 'react';
import { useAuth } from './context/AuthContext';
import { Sidebar } from './components/Sidebar';
import { Navbar } from './components/Navbar';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { MasterLiburPage } from './pages/MasterLiburPage';
import { IzinPage } from './pages/IzinPage';
import { CutiPage } from './pages/CutiPage';
import { SppdPage } from './pages/SppdPage';
import { ReportPage } from './pages/ReportPage';

const VALID_TABS = ['dashboard', 'libur', 'izin', 'cuti', 'sppd', 'laporan'];

const getInitialTab = () => {
  const path = window.location.pathname.replace(/^\//, '').toLowerCase();
  if (VALID_TABS.includes(path)) {
    return path;
  }
  const hash = window.location.hash.replace(/^#\/?/, '').toLowerCase();
  if (VALID_TABS.includes(hash)) {
    return hash;
  }
  const saved = localStorage.getItem('hrportal_active_tab');
  if (VALID_TABS.includes(saved)) {
    return saved;
  }
  return 'dashboard';
};

export const App = () => {
  const { isAuthenticated, loading } = useAuth();
  const [activeTab, setActiveTab] = useState(getInitialTab);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);

  const handleTabChange = (tab) => {
    if (!VALID_TABS.includes(tab)) return;
    setActiveTab(tab);
    localStorage.setItem('hrportal_active_tab', tab);
    if (window.location.pathname !== `/${tab}`) {
      window.history.pushState(null, '', `/${tab}`);
    }
  };

  useEffect(() => {
    const onPopState = () => {
      const path = window.location.pathname.replace(/^\//, '').toLowerCase();
      if (VALID_TABS.includes(path)) {
        setActiveTab(path);
        localStorage.setItem('hrportal_active_tab', path);
      }
    };
    window.addEventListener('popstate', onPopState);
    return () => window.removeEventListener('popstate', onPopState);
  }, []);

  useEffect(() => {
    if (!loading) {
      if (isAuthenticated) {
        const path = window.location.pathname.replace(/^\//, '').toLowerCase();
        if (path === 'login' || path === '' || !VALID_TABS.includes(path)) {
          setActiveTab('dashboard');
          localStorage.setItem('hrportal_active_tab', 'dashboard');
          window.history.pushState(null, '', '/dashboard');
        }
      } else {
        if (window.location.pathname !== '/login') {
          window.history.replaceState(null, '', '/login');
        }
      }
    }
  }, [isAuthenticated, loading]);

  if (loading) {
    return (
      <div
        style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: 'var(--bg-app)',
          color: 'var(--color-primary)',
          fontSize: '1.1rem',
          fontWeight: 600,
        }}
      >
        Memuat HR Portal SDM...
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginPage />;
  }

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <DashboardPage onNavigate={handleTabChange} />;
      case 'libur':
        return <MasterLiburPage />;
      case 'izin':
        return <IzinPage />;
      case 'cuti':
        return <CutiPage />;
      case 'sppd':
        return <SppdPage />;
      case 'laporan':
        return <ReportPage />;
      default:
        return <DashboardPage onNavigate={handleTabChange} />;
    }
  };

  return (
    <div className="app-layout">
      <Sidebar
        activeTab={activeTab}
        onSelectTab={handleTabChange}
        isCollapsed={isSidebarCollapsed}
        onToggleCollapse={() => setIsSidebarCollapsed(!isSidebarCollapsed)}
        isMobileOpen={isMobileSidebarOpen}
        onCloseMobile={() => setIsMobileSidebarOpen(false)}
      />

      <div
        className={`main-content-wrapper ${isSidebarCollapsed ? 'sidebar-collapsed' : ''}`}
      >
        <Navbar
          onToggleMobileSidebar={() => {
            if (window.innerWidth < 1024) {
              setIsMobileSidebarOpen(!isMobileSidebarOpen);
            } else {
              setIsSidebarCollapsed(!isSidebarCollapsed);
            }
          }}
        />

        <main className="content-container">
          {renderContent()}
        </main>
      </div>
    </div>
  );
};
