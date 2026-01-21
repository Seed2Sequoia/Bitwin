import Link from 'next/link';
import { Zap, Droplets, Image as ImageIcon, Users, ArrowRight } from 'lucide-react';

export default function Home() {
  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="bg-linear-to-r from-blue-900/40 to-purple-900/40 border border-blue-800/50 rounded-2xl p-8 backdrop-blur-sm">
        <h1 className="text-4xl font-bold mb-4 bg-linear-to-r from-blue-400 via-purple-400 to-pink-400 text-transparent bg-clip-text">
          Welcome to the Future of DeFi
        </h1>
        <p className="text-xl text-slate-300 max-w-2xl mb-6">
          BitTrust is the first reputation-based lending platform on Stacks offering flash loans,
          NFT collateral, and social credit delegation.
        </p>
        <div className="flex gap-4">
          <Link
            href="/pools"
            className="bg-blue-600 hover:bg-blue-500 text-white px-6 py-3 rounded-lg font-bold transition-all hover:scale-105"
          >
            Start Earning Yield
          </Link>
          <Link
            href="/flash-loans"
            className="bg-slate-800 hover:bg-slate-700 text-white px-6 py-3 rounded-lg font-bold border border-slate-700 transition-all hover:scale-105"
          >
            Explore Flash Loans
          </Link>
        </div>
      </div>

      {/* Feature Grid */}
      <h2 className="text-2xl font-bold pt-4">Platform Features</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">

        <Link href="/flash-loans" className="group">
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-6 h-full transition-all group-hover:border-blue-500/50 group-hover:bg-slate-900/80">
            <div className="w-12 h-12 bg-yellow-500/10 rounded-lg flex items-center justify-center mb-4 text-yellow-500">
              <Zap className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold mb-2 group-hover:text-blue-400 transition-colors">Flash Loans</h3>
            <p className="text-slate-400 text-sm mb-4">
              Borrow any amount without collateral, repay in the same block.
            </p>
            <div className="flex items-center text-blue-500 text-sm font-bold">
              Try It <ArrowRight className="w-4 h-4 ml-1 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>
        </Link>

        <Link href="/pools" className="group">
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-6 h-full transition-all group-hover:border-blue-500/50 group-hover:bg-slate-900/80">
            <div className="w-12 h-12 bg-blue-500/10 rounded-lg flex items-center justify-center mb-4 text-blue-500">
              <Droplets className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold mb-2 group-hover:text-blue-400 transition-colors">Liquidity Pools</h3>
            <p className="text-slate-400 text-sm mb-4">
              Provide liquidity to earn yield or borrow against your assets.
            </p>
            <div className="flex items-center text-blue-500 text-sm font-bold">
              View Pools <ArrowRight className="w-4 h-4 ml-1 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>
        </Link>

        <Link href="/nft" className="group">
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-6 h-full transition-all group-hover:border-blue-500/50 group-hover:bg-slate-900/80">
            <div className="w-12 h-12 bg-purple-500/10 rounded-lg flex items-center justify-center mb-4 text-purple-500">
              <ImageIcon className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold mb-2 group-hover:text-blue-400 transition-colors">NFT Collateral</h3>
            <p className="text-slate-400 text-sm mb-4">
              Unlock liquidity from your blue-chip Stacks NFTs.
            </p>
            <div className="flex items-center text-blue-500 text-sm font-bold">
              Verify NFT <ArrowRight className="w-4 h-4 ml-1 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>
        </Link>

        <Link href="/delegation" className="group">
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-6 h-full transition-all group-hover:border-blue-500/50 group-hover:bg-slate-900/80">
            <div className="w-12 h-12 bg-green-500/10 rounded-lg flex items-center justify-center mb-4 text-green-500">
              <Users className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold mb-2 group-hover:text-blue-400 transition-colors">Credit Delegation</h3>
            <p className="text-slate-400 text-sm mb-4">
              Vouch for users you trust and earn a fee on their repayment.
            </p>
            <div className="flex items-center text-blue-500 text-sm font-bold">
              Delegate <ArrowRight className="w-4 h-4 ml-1 group-hover:translate-x-1 transition-transform" />
            </div>
          </div>
        </Link>

      </div>
    </div>
  );
}
