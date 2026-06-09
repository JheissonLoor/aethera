'use client';

import { useState, useEffect } from 'react';
import { Heart, Zap, Trophy, Vault, Star, Sparkles, Menu, X } from 'lucide-react';

export default function Home() {
  const [activeFeature, setActiveFeature] = useState('pulse');
  const [menuOpen, setMenuOpen] = useState(false);
  const [pulses, setPulses] = useState<Array<{ id: number; x: number; y: number }>>([]);

  // Pulse animation effect
  useEffect(() => {
    if (activeFeature === 'pulse') {
      const interval = setInterval(() => {
        const newPulse = {
          id: Date.now(),
          x: Math.random() * 80 + 10,
          y: Math.random() * 80 + 10,
        };
        setPulses(prev => [...prev, newPulse]);
        setTimeout(() => {
          setPulses(prev => prev.filter(p => p.id !== newPulse.id));
        }, 2000);
      }, 800);
      return () => clearInterval(interval);
    }
  }, [activeFeature]);

  const features = [
    {
      id: 'pulse',
      name: 'Pulse Moments',
      icon: Heart,
      description: 'Real-time emotional microbursts that sync between partners',
      color: 'from-pink-500 to-red-500',
      accent: 'bg-pink-500/20 border-pink-500/50'
    },
    {
      id: 'constellation',
      name: 'Sentiment Constellation',
      icon: Star,
      description: 'Visualize your emotional journey as an evolving constellation',
      color: 'from-cyan-500 to-blue-500',
      accent: 'bg-cyan-500/20 border-cyan-500/50'
    },
    {
      id: 'challenges',
      name: 'Connection Challenges',
      icon: Trophy,
      description: 'Gamified weekly bonding activities with rewards',
      color: 'from-amber-500 to-orange-500',
      accent: 'bg-amber-500/20 border-amber-500/50'
    },
    {
      id: 'vaults',
      name: 'Memory Vaults',
      icon: Vault,
      description: 'Encrypted secrets with conditional reveals',
      color: 'from-purple-500 to-pink-500',
      accent: 'bg-purple-500/20 border-purple-500/50'
    },
    {
      id: 'rituals',
      name: 'Synchronized Rituals',
      icon: Zap,
      description: 'Enhanced ritual experiences with real-time synchronization',
      color: 'from-violet-500 to-purple-500',
      accent: 'bg-violet-500/20 border-violet-500/50'
    },
    {
      id: 'cosmetics',
      name: 'Universe Cosmetics',
      icon: Sparkles,
      description: 'Unlock visual themes through achievements',
      color: 'from-green-500 to-emerald-500',
      accent: 'bg-green-500/20 border-green-500/50'
    },
  ];

  const activeFeatureData = features.find(f => f.id === activeFeature)!;
  const IconComponent = activeFeatureData.icon;

  return (
    <div className="min-h-screen overflow-x-hidden">
      {/* Header */}
      <header className="sticky top-0 z-50 backdrop-blur-md bg-slate-950/80 border-b border-purple-500/20">
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-cyan-500 to-purple-500 flex items-center justify-center">
              <Heart className="w-6 h-6 text-white" />
            </div>
            <h1 className="text-2xl font-bold bg-gradient-to-r from-cyan-400 to-purple-400 bg-clip-text text-transparent">
              Aethera v2.0
            </h1>
          </div>
          <button
            onClick={() => setMenuOpen(!menuOpen)}
            className="md:hidden p-2 hover:bg-purple-500/20 rounded-lg transition"
          >
            {menuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </header>

      {/* Hero Section */}
      <section className="max-w-7xl mx-auto px-4 py-16 md:py-24">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-6xl font-bold mb-4">
            <span className="bg-gradient-to-r from-cyan-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
              Ultra Modern Connection
            </span>
          </h2>
          <p className="text-lg text-gray-300 max-w-2xl mx-auto">
            Experience the next generation of long-distance relationships with 6 revolutionary features, premium animations, and deeply emotional design.
          </p>
        </div>

        {/* Feature Showcase */}
        <div className="grid md:grid-cols-3 gap-4 mb-16">
          {features.map(feature => (
            <button
              key={feature.id}
              onClick={() => { setActiveFeature(feature.id); setMenuOpen(false); }}
              className={`p-4 rounded-2xl backdrop-blur-sm border-2 transition-all transform hover:scale-105 ${
                activeFeature === feature.id
                  ? `${feature.accent} bg-opacity-40 ring-2 ring-offset-2 ring-offset-slate-950 ring-current`
                  : 'bg-slate-900/50 border-slate-700/50 hover:border-slate-600/50'
              }`}
            >
              <div className="flex items-center gap-3 mb-2">
                <feature.icon className="w-5 h-5" />
                <span className="font-semibold text-sm">{feature.name}</span>
              </div>
              <p className="text-xs text-gray-400 text-left">{feature.description}</p>
            </button>
          ))}
        </div>

        {/* Active Feature Detailed View */}
        <div className={`rounded-3xl overflow-hidden backdrop-blur-xl ${activeFeatureData.accent} border-2 p-8 md:p-12 min-h-96`}>
          <div className="flex items-start justify-between mb-8">
            <div>
              <div className="flex items-center gap-3 mb-4">
                <div className={`w-12 h-12 rounded-full bg-gradient-to-br ${activeFeatureData.color} flex items-center justify-center`}>
                  <IconComponent className="w-6 h-6 text-white" />
                </div>
                <h3 className="text-3xl font-bold">{activeFeatureData.name}</h3>
              </div>
              <p className="text-gray-300 text-lg">{activeFeatureData.description}</p>
            </div>
          </div>

          {/* Feature Visualization */}
          <div className="relative h-64 md:h-80 rounded-2xl bg-gradient-to-br from-slate-900/50 to-slate-800/50 border border-slate-700/50 overflow-hidden">
            {activeFeature === 'pulse' && (
              <div className="w-full h-full relative">
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-32 h-32 rounded-full bg-gradient-to-br from-pink-500 to-red-500 opacity-20 animate-pulse" />
                </div>
                {pulses.map(pulse => (
                  <div
                    key={pulse.id}
                    className="absolute w-16 h-16 rounded-full border-2 border-pink-500/50 animate-ping"
                    style={{
                      left: `${pulse.x}%`,
                      top: `${pulse.y}%`,
                      transform: 'translate(-50%, -50%)',
                    }}
                  />
                ))}
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="text-center">
                    <Heart className="w-16 h-16 text-pink-500 mx-auto mb-4 animate-bounce" />
                    <p className="text-white font-semibold">Emotional Sync Active</p>
                  </div>
                </div>
              </div>
            )}

            {activeFeature === 'constellation' && (
              <svg className="w-full h-full" viewBox="0 0 400 300">
                <defs>
                  <linearGradient id="starGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#06b6d4" />
                    <stop offset="100%" stopColor="#3b82f6" />
                  </linearGradient>
                </defs>
                {/* Draw constellation points and lines */}
                {[
                  { x: 60, y: 50 },
                  { x: 150, y: 80 },
                  { x: 250, y: 100 },
                  { x: 320, y: 150 },
                  { x: 280, y: 220 },
                  { x: 150, y: 240 },
                  { x: 80, y: 200 },
                ].map((point, i, arr) => (
                  <line
                    key={`line-${i}`}
                    x1={point.x}
                    y1={point.y}
                    x2={arr[(i + 1) % arr.length].x}
                    y2={arr[(i + 1) % arr.length].y}
                    stroke="url(#starGradient)"
                    strokeWidth="2"
                    opacity="0.6"
                  />
                ))}
                {[
                  { x: 60, y: 50 },
                  { x: 150, y: 80 },
                  { x: 250, y: 100 },
                  { x: 320, y: 150 },
                  { x: 280, y: 220 },
                  { x: 150, y: 240 },
                  { x: 80, y: 200 },
                ].map((point, i) => (
                  <circle
                    key={`star-${i}`}
                    cx={point.x}
                    cy={point.y}
                    r="8"
                    fill="url(#starGradient)"
                    className="animate-pulse"
                    style={{ animationDelay: `${i * 0.1}s` }}
                  />
                ))}
              </svg>
            )}

            {activeFeature === 'challenges' && (
              <div className="w-full h-full flex flex-col items-center justify-center gap-6">
                <div className="grid grid-cols-3 gap-4 w-full px-4">
                  {['Week 1', 'Week 2', 'Week 3'].map((week, i) => (
                    <div key={i} className="aspect-square rounded-lg bg-gradient-to-br from-amber-500/30 to-orange-500/30 border border-amber-500/50 flex items-center justify-center">
                      <span className="font-bold text-amber-300">{week}</span>
                    </div>
                  ))}
                </div>
                <div className="flex items-center gap-2 text-amber-300">
                  <Trophy className="w-5 h-5" />
                  <span>Earn cosmetics & boost connection</span>
                </div>
              </div>
            )}

            {activeFeature === 'vaults' && (
              <div className="w-full h-full flex items-center justify-center">
                <div className="relative group">
                  <div className="absolute inset-0 rounded-xl bg-gradient-to-r from-purple-500 to-pink-500 opacity-75 blur group-hover:opacity-100 transition" />
                  <div className="relative rounded-xl bg-slate-900 p-6 backdrop-blur-sm">
                    <Vault className="w-12 h-12 text-purple-400 mx-auto mb-4" />
                    <p className="text-center text-sm text-gray-300">Click to reveal secret</p>
                    <p className="text-center text-xs text-gray-500 mt-2">Encrypted & private</p>
                  </div>
                </div>
              </div>
            )}

            {activeFeature === 'rituals' && (
              <div className="w-full h-full flex items-center justify-center gap-8">
                <div className="text-center">
                  <div className="w-20 h-20 rounded-full bg-violet-500/30 border-2 border-violet-500/50 flex items-center justify-center mx-auto mb-2 animate-pulse">
                    <span className="text-2xl font-bold text-violet-300">You</span>
                  </div>
                  <p className="text-sm text-gray-400">Synced</p>
                </div>
                <Zap className="w-8 h-8 text-violet-400" />
                <div className="text-center">
                  <div className="w-20 h-20 rounded-full bg-violet-500/30 border-2 border-violet-500/50 flex items-center justify-center mx-auto mb-2 animate-pulse" style={{ animationDelay: '0.3s' }}>
                    <span className="text-2xl font-bold text-violet-300">Partner</span>
                  </div>
                  <p className="text-sm text-gray-400">Synced</p>
                </div>
              </div>
            )}

            {activeFeature === 'cosmetics' && (
              <div className="w-full h-full grid grid-cols-3 gap-4 p-4">
                {[
                  { name: 'Aurora Paradise', icon: '✨', locked: false },
                  { name: 'Deep Ocean', icon: '🌊', locked: false },
                  { name: 'Bioluminescent', icon: '🌿', locked: true },
                ].map((cosmetic, i) => (
                  <div
                    key={i}
                    className={`rounded-lg flex flex-col items-center justify-center p-3 border-2 transition ${
                      cosmetic.locked
                        ? 'bg-slate-900/50 border-slate-700/50 opacity-50'
                        : 'bg-green-500/20 border-green-500/50'
                    }`}
                  >
                    <span className="text-3xl mb-2">{cosmetic.icon}</span>
                    <p className="text-xs font-semibold text-center">{cosmetic.name}</p>
                    {cosmetic.locked && <p className="text-xs text-gray-500 mt-1">Locked</p>}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Feature Benefits */}
          <div className="grid md:grid-cols-2 gap-4 mt-8">
            {activeFeature === 'pulse' && (
              <>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-pink-400 mb-2">Real-time Sync</p>
                  <p className="text-sm text-gray-400">Heartbeat-synced emotional signals visible to both partners instantly</p>
                </div>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-pink-400 mb-2">Pulse Streaks</p>
                  <p className="text-sm text-gray-400">Build momentum with daily emotional connections and achieve milestones</p>
                </div>
              </>
            )}
            {activeFeature === 'constellation' && (
              <>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-cyan-400 mb-2">Visual Timeline</p>
                  <p className="text-sm text-gray-400">See your emotional journey mapped as beautiful constellations over 30 days</p>
                </div>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-cyan-400 mb-2">Share Snapshots</p>
                  <p className="text-sm text-gray-400">Capture and share your constellation patterns with your partner</p>
                </div>
              </>
            )}
            {activeFeature === 'challenges' && (
              <>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-amber-400 mb-2">Daily Challenges</p>
                  <p className="text-sm text-gray-400">3-5 minute activities designed to deepen connection and intimacy</p>
                </div>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-amber-400 mb-2">Cosmetic Rewards</p>
                  <p className="text-sm text-gray-400">Unlock exclusive universe themes and effects through challenge completion</p>
                </div>
              </>
            )}
            {activeFeature === 'vaults' && (
              <>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-purple-400 mb-2">Encrypted Storage</p>
                  <p className="text-sm text-gray-400">Secrets and wishes stored securely, visible only when you choose</p>
                </div>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-purple-400 mb-2">Reveal Conditions</p>
                  <p className="text-sm text-gray-400">Set custom conditions like dates or relationship milestones for reveals</p>
                </div>
              </>
            )}
            {activeFeature === 'rituals' && (
              <>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-violet-400 mb-2">Real-time Reveals</p>
                  <p className="text-sm text-gray-400">Answers synchronize and reveal simultaneously for both partners</p>
                </div>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-violet-400 mb-2">Ritual Insights</p>
                  <p className="text-sm text-gray-400">Generate compatibility scores and emotional pattern analysis after each ritual</p>
                </div>
              </>
            )}
            {activeFeature === 'cosmetics' && (
              <>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-green-400 mb-2">Multiple Themes</p>
                  <p className="text-sm text-gray-400">Aurora Paradise, Deep Ocean, Bioluminescent Forest, and more</p>
                </div>
                <div className="p-4 rounded-lg bg-slate-900/50 border border-slate-700/50">
                  <p className="font-semibold text-green-400 mb-2">Partner Customization</p>
                  <p className="text-sm text-gray-400">Customize your partner's half of the universe with exclusive effects</p>
                </div>
              </>
            )}
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="max-w-7xl mx-auto px-4 py-16">
        <div className="grid md:grid-cols-4 gap-4">
          {[
            { label: 'New Features', value: '6' },
            { label: 'Premium Widgets', value: '4' },
            { label: 'New Firebase Collections', value: '5' },
            { label: 'Lines of Code', value: '5500+' },
          ].map((stat, i) => (
            <div key={i} className="p-6 rounded-2xl backdrop-blur-sm bg-slate-900/50 border border-slate-700/50 text-center hover:border-purple-500/50 transition">
              <p className="text-3xl font-bold bg-gradient-to-r from-cyan-400 to-purple-400 bg-clip-text text-transparent mb-2">
                {stat.value}
              </p>
              <p className="text-gray-400">{stat.label}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-purple-500/20 mt-16 py-8">
        <div className="max-w-7xl mx-auto px-4 text-center text-gray-500">
          <p>Aethera v2.0 - Ultra Modern Connection for Long Distance Couples</p>
        </div>
      </footer>
    </div>
  );
}
