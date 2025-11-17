"use client"

import { useState } from "react"

export function SettingsPage() {
  const [businessName, setBusinessName] = useState("Coffee Shop 2025")
  const [currency, setCurrency] = useState("PHP")
  const [notifications, setNotifications] = useState(true)
  const [darkMode, setDarkMode] = useState(false)

  const handleSave = () => {
    alert("Settings saved successfully!")
  }

  return (
    <div className="px-4 pt-6 pb-4 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Settings</h1>
          <p className="text-sm text-muted-foreground">Manage your app preferences</p>
        </div>
      </div>

      {/* Business Settings */}
      <div className="space-y-4">
        <h2 className="text-lg font-bold text-foreground">Business Settings</h2>

        {/* Business Name */}
        <div className="bg-card rounded-lg p-4 border border-border">
          <label className="block text-sm font-medium text-foreground mb-2">Business Name</label>
          <input
            type="text"
            value={businessName}
            onChange={(e) => setBusinessName(e.target.value)}
            className="w-full px-4 py-2 rounded-lg border border-border bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>

        {/* Currency */}
        <div className="bg-card rounded-lg p-4 border border-border">
          <label className="block text-sm font-medium text-foreground mb-2">Currency</label>
          <select
            value={currency}
            onChange={(e) => setCurrency(e.target.value)}
            className="w-full px-4 py-2 rounded-lg border border-border bg-background text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
          >
            <option>PHP</option>
            <option>USD</option>
            <option>EUR</option>
          </select>
        </div>
      </div>

      {/* App Preferences */}
      <div className="space-y-4">
        <h2 className="text-lg font-bold text-foreground">App Preferences</h2>

        {/* Notifications Toggle */}
        <div className="flex items-center justify-between bg-card rounded-lg p-4 border border-border">
          <div>
            <p className="font-medium text-foreground">Enable Notifications</p>
            <p className="text-xs text-muted-foreground">Get alerts for important updates</p>
          </div>
          <button
            onClick={() => setNotifications(!notifications)}
            className={`relative w-12 h-7 rounded-full transition-colors ${notifications ? "bg-primary" : "bg-secondary"}`}
          >
            <div
              className={`absolute top-1 left-1 w-5 h-5 bg-white rounded-full transition-transform ${notifications ? "translate-x-5" : ""}`}
            />
          </button>
        </div>

        {/* Dark Mode Toggle */}
        <div className="flex items-center justify-between bg-card rounded-lg p-4 border border-border">
          <div>
            <p className="font-medium text-foreground">Dark Mode</p>
            <p className="text-xs text-muted-foreground">Coming soon</p>
          </div>
          <button
            disabled
            className={`relative w-12 h-7 rounded-full transition-colors ${darkMode ? "bg-primary" : "bg-secondary"} opacity-50`}
          >
            <div
              className={`absolute top-1 left-1 w-5 h-5 bg-white rounded-full transition-transform ${darkMode ? "translate-x-5" : ""}`}
            />
          </button>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="space-y-3 pt-6">
        <button
          onClick={handleSave}
          className="w-full py-3 px-4 rounded-lg bg-primary text-primary-foreground font-bold hover:bg-primary/90 transition-colors"
        >
          Save Settings
        </button>
        <button className="w-full py-3 px-4 rounded-lg border border-border text-foreground font-medium hover:bg-secondary transition-colors">
          Export Data
        </button>
        <button className="w-full py-3 px-4 rounded-lg border border-red-500 text-red-600 font-medium hover:bg-red-50 transition-colors">
          Clear All Data
        </button>
      </div>

      {/* About */}
      <div className="bg-card rounded-lg p-4 border border-border text-center">
        <p className="text-sm font-medium text-foreground">CoffeeFlow</p>
        <p className="text-xs text-muted-foreground">v1.0.0</p>
        <p className="text-xs text-muted-foreground mt-2">Simple Coffee Shop Money Tracker</p>
      </div>
    </div>
  )
}
