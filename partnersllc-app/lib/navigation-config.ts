export interface NavItem {
  href: string;
  icon: string;
  label: string;
}

export interface NavSection {
  label: string;
  items: NavItem[];
}

export interface NavConfig {
  sections: NavSection[];
}

export const clientNavConfig: NavConfig = {
  sections: [
    {
      label: "Menu",
      items: [
        {
          href: "/dashboard",
          icon: "fa-chart-pie",
          label: "Tableau de bord",
        },
        {
          href: "/dashboard/dossier",
          icon: "fa-list-check",
          label: "Mon dossier LLC",
        },
        {
          href: "/dashboard/documents",
          icon: "fa-folder-open",
          label: "Documents",
        },
        {
          href: "/dashboard/entreprise",
          icon: "fa-building",
          label: "Mon entreprise",
        },
        {
          href: "/dashboard/hub",
          icon: "fa-users",
          label: "PARTNERS Hub",
        },
        {
          href: "/dashboard/formation",
          icon: "fa-graduation-cap",
          label: "Formation",
        },
      ],
    },
    {
      label: "Support",
      items: [
        {
          href: "/dashboard/support",
          icon: "fa-headset",
          label: "Support",
        },
        {
          href: "/dashboard/profile",
          icon: "fa-gear",
          label: "Paramètres",
        },
      ],
    },
  ],
};

export const adminNavConfig: NavConfig = {
  sections: [
    {
      label: "Menu",
      items: [
        {
          href: "/admin",
          icon: "fa-chart-pie",
          label: "Vue d'ensemble",
        },
        {
          href: "/admin/clients",
          icon: "fa-users-gear",
          label: "Gestion Clients",
        },
        {
          href: "/admin/dossiers",
          icon: "fa-folder-tree",
          label: "Dossiers LLC",
        },
        {
          href: "/admin/facturation",
          icon: "fa-file-invoice-dollar",
          label: "Facturation",
        },
      ],
    },
    {
      label: "Outils",
      items: [
        {
          href: "/admin/notifications",
          icon: "fa-bullhorn",
          label: "Notifications",
        },
        {
          href: "/admin/rapports",
          icon: "fa-chart-line",
          label: "Rapports",
        },
        {
          href: "/admin/settings",
          icon: "fa-gear",
          label: "Paramètres",
        },
      ],
    },
  ],
};
