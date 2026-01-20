// BitTrust Application Logic

// Configuration
const CONTRACT_ADDRESS = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'; // Update with deployed address
const CONTRACT_NAME_CORE = 'bittrust-core';
const CONTRACT_NAME_REPUTATION = 'reputation-system';
const NETWORK = 'testnet'; // or 'mainnet'

// State
let userAddress = null;
let userSession = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    initializeApp();
    setupEventListeners();
});

function initializeApp() {
    // Check if wallet is already connected
    const savedAddress = localStorage.getItem('userAddress');
    if (savedAddress) {
        userAddress = savedAddress;
        updateUIForConnectedWallet();
    }
}

function setupEventListeners() {
    // Navigation
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const view = btn.dataset.view;
            switchView(view);
        });
    });

    // Connect Wallet
    document.getElementById('connectWallet').addEventListener('click', connectWallet);

    // Lend Form
    document.getElementById('lendForm').addEventListener('submit', handleCreateLoan);

    // Initialize Reputation
    const initRepBtn = document.getElementById('initReputation');
    if (initRepBtn) {
        initRepBtn.addEventListener('click', initializeReputation);
    }
}

function switchView(viewName) {
    // Update navigation
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.view === viewName) {
            btn.classList.add('active');
        }
    });

    // Update views
    document.querySelectorAll('.view').forEach(view => {
        view.classList.remove('active');
    });
    document.getElementById(`${viewName}View`).classList.add('active');

    // Load view-specific data
    if (userAddress) {
        switch(viewName) {
            case 'dashboard':
                loadDashboardData();
                break;
            case 'borrow':
                loadActiveLoans();
                break;
            case 'reputation':
                loadReputationData();
                break;
        }
    }
}

async function connectWallet() {
    try {
        showToast('Connecting wallet...', 'info');
        
        // Using Stacks Connect
        const { userSession } = await window.StacksConnect.showConnect({
            appDetails: {
                name: 'BitTrust',
                icon: window.location.origin + '/logo.png',
            },
            redirectTo: '/',
            onFinish: () => {
                const userData = userSession.loadUserData();
                userAddress = userData.profile.stxAddress.testnet;
                localStorage.setItem('userAddress', userAddress);
                updateUIForConnectedWallet();
                showToast('Wallet connected successfully!', 'success');
            },
            onCancel: () => {
                showToast('Wallet connection cancelled', 'error');
            },
        });
    } catch (error) {
        console.error('Wallet connection error:', error);
        showToast('Failed to connect wallet', 'error');
    }
}

function updateUIForConnectedWallet() {
    const connectBtn = document.getElementById('connectWallet');
    connectBtn.textContent = `${userAddress.slice(0, 6)}...${userAddress.slice(-4)}`;
    connectBtn.classList.add('connected');
    
    // Show user stats section
    const userStatsSection = document.getElementById('userStatsSection');
    if (userStatsSection) {
        userStatsSection.style.display = 'block';
    }
    
    // Load initial data
    loadDashboardData();
}

async function loadDashboardData() {
    if (!userAddress) return;
    
    try {
        // Load user stats
        const stats = await getUserStats(userAddress);
        updateUserStatsUI(stats);
        
        // Load platform stats (mock for now)
        document.getElementById('totalLoans').textContent = '156';
        document.getElementById('totalVolume').textContent = '45,230 STX';
        document.getElementById('avgReputation').textContent = '687';
    } catch (error) {
        console.error('Error loading dashboard:', error);
    }
}

async function getUserStats(address) {
    // In production, this would call the smart contract
    // For now, return mock data
    return {
        totalBorrowed: 0,
        totalLent: 0,
        activeBorrowed: 0,
        activeLent: 0,
        totalRepaid: 0,
        defaults: 0
    };
}

function updateUserStatsUI(stats) {
    document.getElementById('userBorrowed').textContent = `${(stats.totalBorrowed / 1000000).toFixed(2)} STX`;
    document.getElementById('userActiveBorrowed').textContent = stats.activeBorrowed;
    document.getElementById('userRepaid').textContent = `${(stats.totalRepaid / 1000000).toFixed(2)} STX`;
    document.getElementById('userLent').textContent = `${(stats.totalLent / 1000000).toFixed(2)} STX`;
    document.getElementById('userActiveLent').textContent = stats.activeLent;
    document.getElementById('userDefaults').textContent = stats.defaults;
}

async function handleCreateLoan(e) {
    e.preventDefault();
    
    if (!userAddress) {
        showToast('Please connect your wallet first', 'error');
        return;
    }
    
    const formData = {
        borrower: document.getElementById('lendBorrower').value,
        amount: parseFloat(document.getElementById('lendAmount').value) * 1000000, // Convert to microSTX
        collateralAmount: 0, // Will be provided by borrower
        interestRate: Math.floor(parseFloat(document.getElementById('lendInterest').value) * 100), // Convert to basis points
        duration: parseInt(document.getElementById('lendDuration').value),
        minCollateralRatio: parseInt(document.getElementById('lendCollateral').value)
    };
    
    try {
        showToast('Creating loan...', 'info');
        
        // In production, this would call the smart contract
        // For demonstration, we'll simulate success
        setTimeout(() => {
            showToast('Loan created successfully!', 'success');
            e.target.reset();
            switchView('dashboard');
        }, 2000);
        
        // Actual contract call would look like:
        /*
        const txOptions = {
            contractAddress: CONTRACT_ADDRESS,
            contractName: CONTRACT_NAME_CORE,
            functionName: 'create-loan',
            functionArgs: [
                principalCV(formData.borrower),
                uintCV(formData.amount),
                uintCV(formData.collateralAmount),
                uintCV(formData.interestRate),
                uintCV(formData.duration),
                uintCV(formData.minCollateralRatio)
            ],
            network: NETWORK,
            onFinish: (data) => {
                showToast('Loan created successfully!', 'success');
                loadDashboardData();
            },
            onCancel: () => {
                showToast('Transaction cancelled', 'error');
            }
        };
        await openContractCall(txOptions);
        */
    } catch (error) {
        console.error('Error creating loan:', error);
        showToast('Failed to create loan', 'error');
    }
}

async function loadActiveLoans() {
    if (!userAddress) {
        document.getElementById('activeLoans').innerHTML = `
            <div class="empty-state">
                <p>Please connect your wallet to view your loans.</p>
            </div>
        `;
        return;
    }
    
    // In production, fetch from contract
    // For now, show mock data
    const mockLoans = [
        {
            id: 1,
            borrower: userAddress,
            lender: 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7',
            amount: 1000,
            collateral: 1500,
            interestRate: 10,
            dueBlock: 12345,
            status: 'active',
            repaidAmount: 0
        }
    ];
    
    if (mockLoans.length === 0) {
        document.getElementById('activeLoans').innerHTML = `
            <div class="empty-state">
                <p>No active loans found.</p>
            </div>
        `;
        return;
    }
    
    const loansHTML = mockLoans.map(loan => `
        <div class="loan-card">
            <div class="loan-header">
                <span class="loan-id">Loan #${loan.id}</span>
                <span class="loan-status ${loan.status}">${loan.status}</span>
            </div>
            <div class="loan-details">
                <div class="loan-detail">
                    <span>Amount:</span>
                    <span>${loan.amount} STX</span>
                </div>
                <div class="loan-detail">
                    <span>Collateral:</span>
                    <span>${loan.collateral} STX</span>
                </div>
                <div class="loan-detail">
                    <span>Interest Rate:</span>
                    <span>${loan.interestRate}%</span>
                </div>
                <div class="loan-detail">
                    <span>Repaid:</span>
                    <span>${loan.repaidAmount} STX</span>
                </div>
            </div>
            ${loan.status === 'active' ? `
                <div class="loan-actions">
                    <button class="btn btn-primary" onclick="repayLoan(${loan.id})">Repay</button>
                </div>
            ` : ''}
        </div>
    `).join('');
    
    document.getElementById('activeLoans').innerHTML = loansHTML;
}

async function repayLoan(loanId) {
    if (!userAddress) {
        showToast('Please connect your wallet', 'error');
        return;
    }
    
    const amount = prompt('Enter repayment amount (STX):');
    if (!amount || isNaN(amount)) return;
    
    try {
        showToast('Processing repayment...', 'info');
        
        // Simulate transaction
        setTimeout(() => {
            showToast('Repayment successful!', 'success');
            loadActiveLoans();
        }, 2000);
    } catch (error) {
        console.error('Repayment error:', error);
        showToast('Repayment failed', 'error');
    }
}

async function loadReputationData() {
    if (!userAddress) return;
    
    try {
        // In production, fetch from reputation contract
        const mockReputation = {
            score: 750,
            totalLoans: 12,
            successfulRepayments: 11,
            defaults: 0,
            totalVolume: 15000,
            borrowingLimit: 5000,
            recommendedRate: 8.5
        };
        
        updateReputationUI(mockReputation);
    } catch (error) {
        console.error('Error loading reputation:', error);
        document.getElementById('initReputation').style.display = 'block';
    }
}

function updateReputationUI(rep) {
    // Update score circle
    const circle = document.getElementById('reputationCircle');
    const circumference = 2 * Math.PI * 90;
    const offset = circumference - (rep.score / 1000) * circumference;
    circle.style.strokeDashoffset = offset;
    
    // Update values
    document.getElementById('reputationScore').textContent = rep.score;
    document.getElementById('repTotalLoans').textContent = rep.totalLoans;
    document.getElementById('repSuccessful').textContent = rep.successfulRepayments;
    document.getElementById('repDefaults').textContent = rep.defaults;
    document.getElementById('repVolume').textContent = `${(rep.totalVolume / 1000000).toFixed(2)} STX`;
    document.getElementById('repLimit').textContent = `${(rep.borrowingLimit / 1000000).toFixed(2)} STX`;
    document.getElementById('repRate').textContent = `${rep.recommendedRate}%`;
}

async function initializeReputation() {
    if (!userAddress) {
        showToast('Please connect your wallet', 'error');
        return;
    }
    
    try {
        showToast('Initializing reputation...', 'info');
        
        // Simulate transaction
        setTimeout(() => {
            showToast('Reputation initialized!', 'success');
            document.getElementById('initReputation').style.display = 'none';
            loadReputationData();
        }, 2000);
    } catch (error) {
        console.error('Error initializing reputation:', error);
        showToast('Failed to initialize reputation', 'error');
    }
}

function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    
    container.appendChild(toast);
    
    setTimeout(() => {
        toast.style.animation = 'slideIn 0.3s ease reverse';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

// Utility functions
function formatSTX(microSTX) {
    return (microSTX / 1000000).toFixed(6);
}

function formatAddress(address) {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
}
