// Download functionality
function downloadApp() {
    // Show download confirmation
    if (confirm('Download HeartLink APK?\n\nFile size: ~25 MB\nVersion: 1.0.0\n\nMake sure you have enabled "Unknown Sources" in your Android settings.')) {
        
        // Track download
        trackDownload();
        
        // Start download
        const link = document.createElement('a');
        link.href = '/download'; // FastAPI download route
        link.download = 'HeartLink-v1.0.0.apk';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        // Show installation guide
        setTimeout(() => {
            showInstallationGuide();
        }, 1000);
    }
}

// Track download analytics
function trackDownload() {
    // Simple analytics tracking
    const downloadData = {
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        referrer: document.referrer
    };
    
    // Store in localStorage for basic analytics
    let downloads = JSON.parse(localStorage.getItem('downloads') || '[]');
    downloads.push(downloadData);
    localStorage.setItem('downloads', JSON.stringify(downloads));
    
    console.log('Download tracked:', downloadData);
}

// Show installation guide popup
function showInstallationGuide() {
    const modal = document.createElement('div');
    modal.className = 'install-modal';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3>📱 Installation Guide</h3>
                <button class="close-btn" onclick="closeModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div class="install-step">
                    <div class="step-icon">⚙️</div>
                    <div>
                        <h4>Step 1: Enable Unknown Sources</h4>
                        <p>Go to Settings → Security → Enable "Install from Unknown Sources"</p>
                    </div>
                </div>
                <div class="install-step">
                    <div class="step-icon">📥</div>
                    <div>
                        <h4>Step 2: Open Downloaded File</h4>
                        <p>Find the HeartLink APK in your Downloads folder and tap it</p>
                    </div>
                </div>
                <div class="install-step">
                    <div class="step-icon">✅</div>
                    <div>
                        <h4>Step 3: Install & Enjoy</h4>
                        <p>Follow the installation prompts and start finding your perfect match!</p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="got-it-btn" onclick="closeModal()">Got it! 👍</button>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    // Add modal styles
    const style = document.createElement('style');
    style.textContent = `
        .install-modal {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.8);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10000;
            animation: fadeIn 0.3s ease;
        }
        
        .modal-content {
            background: white;
            border-radius: 20px;
            max-width: 500px;
            width: 90%;
            max-height: 80vh;
            overflow-y: auto;
            animation: slideUp 0.3s ease;
        }
        
        .modal-header {
            padding: 20px;
            border-bottom: 1px solid #eee;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .modal-header h3 {
            margin: 0;
            color: #333;
        }
        
        .close-btn {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #999;
        }
        
        .modal-body {
            padding: 20px;
        }
        
        .install-step {
            display: flex;
            gap: 15px;
            margin-bottom: 20px;
            align-items: flex-start;
        }
        
        .step-icon {
            font-size: 24px;
            width: 40px;
            text-align: center;
        }
        
        .install-step h4 {
            margin: 0 0 5px 0;
            color: #333;
        }
        
        .install-step p {
            margin: 0;
            color: #666;
            line-height: 1.5;
        }
        
        .modal-footer {
            padding: 20px;
            border-top: 1px solid #eee;
            text-align: center;
        }
        
        .got-it-btn {
            background: linear-gradient(135deg, #FF6B9D, #FF8E8E);
            color: white;
            border: none;
            padding: 12px 30px;
            border-radius: 25px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
            transition: transform 0.3s;
        }
        
        .got-it-btn:hover {
            transform: scale(1.05);
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes slideUp {
            from { transform: translateY(50px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
    `;
    document.head.appendChild(style);
}

// Close modal
function closeModal() {
    const modal = document.querySelector('.install-modal');
    if (modal) {
        modal.style.animation = 'fadeOut 0.3s ease';
        setTimeout(() => {
            modal.remove();
        }, 300);
    }
}

// Smooth scrolling for navigation links
document.addEventListener('DOMContentLoaded', function() {
    const navLinks = document.querySelectorAll('.nav a[href^="#"]');
    
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            
            if (targetSection) {
                targetSection.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
});

// Screenshot gallery lightbox
document.addEventListener('DOMContentLoaded', function() {
    const screenshots = document.querySelectorAll('.screenshot-item img');
    
    screenshots.forEach(img => {
        img.addEventListener('click', function() {
            showLightbox(this.src, this.alt);
        });
    });
});

function showLightbox(src, alt) {
    const lightbox = document.createElement('div');
    lightbox.className = 'lightbox';
    lightbox.innerHTML = `
        <div class="lightbox-content">
            <img src="${src}" alt="${alt}">
            <button class="lightbox-close" onclick="closeLightbox()">&times;</button>
        </div>
    `;
    
    document.body.appendChild(lightbox);
    
    // Add lightbox styles
    const style = document.createElement('style');
    style.textContent = `
        .lightbox {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.9);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10000;
            animation: fadeIn 0.3s ease;
        }
        
        .lightbox-content {
            position: relative;
            max-width: 90%;
            max-height: 90%;
        }
        
        .lightbox img {
            max-width: 100%;
            max-height: 100%;
            border-radius: 10px;
        }
        
        .lightbox-close {
            position: absolute;
            top: -40px;
            right: 0;
            background: none;
            border: none;
            color: white;
            font-size: 30px;
            cursor: pointer;
        }
    `;
    document.head.appendChild(style);
}

function closeLightbox() {
    const lightbox = document.querySelector('.lightbox');
    if (lightbox) {
        lightbox.remove();
    }
}

// Add fade-in animation on scroll
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

document.addEventListener('DOMContentLoaded', function() {
    const animatedElements = document.querySelectorAll('.feature-card, .screenshot-item, .step');
    
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

// Add CSS for fade out animation
const fadeOutStyle = document.createElement('style');
fadeOutStyle.textContent = `
    @keyframes fadeOut {
        from { opacity: 1; }
        to { opacity: 0; }
    }
`;
document.head.appendChild(fadeOutStyle);