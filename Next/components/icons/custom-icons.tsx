export const Icons = {
  // Navigation Icons
  Dashboard: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <rect x="3" y="3" width="8" height="8" rx="1" stroke="currentColor" strokeWidth="1.5" />
      <rect x="13" y="3" width="8" height="8" rx="1" stroke="currentColor" strokeWidth="1.5" />
      <rect x="3" y="13" width="8" height="8" rx="1" stroke="currentColor" strokeWidth="1.5" />
      <rect x="13" y="13" width="8" height="8" rx="1" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  ),

  Sales: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <path
        d="M3 21V8c0-1 .5-2 1.5-2h3V3h8v3h3c1 0 1.5 1 1.5 2v13"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
      <path d="M9 17v-4m6 4v-8" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  ),

  Expenses: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <path
        d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"
        fill="currentColor"
      />
      <path d="M12 7v5.5m0 2.5a.5.5 0 100-1 .5.5 0 000 1z" fill="currentColor" />
    </svg>
  ),

  Settings: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.5" />
      <path
        d="M12 1v3m0 16v3M4.22 4.22l2.12 2.12M17.66 17.66l2.12 2.12M1 12h3m16 0h3M4.22 19.78l2.12-2.12M17.66 6.34l2.12-2.12"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
    </svg>
  ),

  // Transaction Icons
  Income: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <path
        d="M12 2L2 8v8c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V8l-10-6z"
        stroke="currentColor"
        strokeWidth="1.5"
      />
      <path d="M8 13l2 2 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  ),

  Expense: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="1.5" />
      <path d="M7 12h10" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  ),

  Wallet: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <rect x="2" y="5" width="20" height="14" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M2 9h20" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="18" cy="14" r="1.5" fill="currentColor" />
    </svg>
  ),

  CreditCard: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <rect x="2" y="5" width="20" height="14" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <path d="M2 10h20" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="6" cy="17" r="1" fill="currentColor" />
      <line x1="9" y1="16.5" x2="11" y2="16.5" stroke="currentColor" strokeWidth="1" strokeLinecap="round" />
    </svg>
  ),

  Mobile: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <rect x="5" y="2" width="14" height="20" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <circle cx="12" cy="19" r="1.5" fill="currentColor" />
      <rect x="5" y="2" width="14" height="14" rx="0" stroke="none" />
    </svg>
  ),

  TrendDown: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <path d="M3 6v12m5-12v9m5-9v3m5-3v6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  ),

  BarChart: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <rect x="3" y="11" width="3" height="9" rx="1" stroke="currentColor" strokeWidth="1.5" />
      <rect x="10" y="6" width="3" height="14" rx="1" stroke="currentColor" strokeWidth="1.5" />
      <rect x="17" y="3" width="3" height="17" rx="1" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  ),

  // Action Icons
  Plus: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <path d="M12 5v14M5 12h14" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  ),

  Menu: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <path d="M3 6h18M3 12h18M3 18h18" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  ),

  // Status Icons
  TrendUp: (props: any) => (
    <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" {...props}>
      <path d="M3 18v-6m5 6v-9m5 9v-3m5 3V6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  ),
}
