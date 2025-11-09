export default function Home() {
  const apiUrl: string = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8001'
  
  return (
    <main style={{
      minHeight: '100vh',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      padding: '2rem'
    }}>
      <div style={{ 
        textAlign: 'center', 
        color: 'white',
        maxWidth: '800px'
      }}>
        <h1 style={{ 
          fontSize: '4rem', 
          fontWeight: 'bold', 
          marginBottom: '1rem',
          textShadow: '2px 2px 4px rgba(0,0,0,0.3)'
        }}>
          🔍 Antiplagiat
        </h1>
        
        <p style={{ 
          fontSize: '1.5rem', 
          marginBottom: '2rem', 
          opacity: 0.95 
        }}>
          Production-Ready Plagiarism Detection Platform
        </p>
        
        <div style={{ 
          background: 'rgba(255,255,255,0.1)',
          backdropFilter: 'blur(10px)',
          padding: '2rem',
          borderRadius: '16px',
          marginBottom: '2rem'
        }}>
          <h2 style={{ fontSize: '1.25rem', marginBottom: '1rem' }}>
            ✨ Features
          </h2>
          <ul style={{ 
            listStyle: 'none', 
            padding: 0,
            fontSize: '1.1rem',
            lineHeight: '2'
          }}>
            <li>🚀 Fast & Deep Analysis Modes</li>
            <li>🧠 ML-Powered Detection</li>
            <li>📊 Detailed Reports</li>
            <li>🌍 Multi-language Support (RU/EN)</li>
            <li>⚡ Built with TypeScript</li>
          </ul>
        </div>
        
        <div style={{ 
          display: 'flex', 
          gap: '1rem', 
          justifyContent: 'center',
          flexWrap: 'wrap'
        }}>
          <a 
            href="/check" 
            style={{
              padding: '1rem 2rem',
              background: 'white',
              color: '#667eea',
              borderRadius: '8px',
              textDecoration: 'none',
              fontWeight: 'bold',
              fontSize: '1.1rem',
              boxShadow: '0 4px 6px rgba(0,0,0,0.2)',
              transition: 'transform 0.2s'
            }}
          >
            Start Check
          </a>
          
          <a 
            href={`${apiUrl}/docs`}
            target="_blank"
            rel="noopener noreferrer"
            style={{
              padding: '1rem 2rem',
              background: 'rgba(255,255,255,0.2)',
              color: 'white',
              borderRadius: '8px',
              textDecoration: 'none',
              border: '2px solid white',
              fontWeight: 'bold',
              fontSize: '1.1rem',
              boxShadow: '0 4px 6px rgba(0,0,0,0.2)'
            }}
          >
            API Docs
          </a>
        </div>
        
        <p style={{ 
          marginTop: '2rem', 
          opacity: 0.8,
          fontSize: '0.9rem'
        }}>
          Powered by Next.js + TypeScript + FastAPI
        </p>
      </div>
    </main>
  )
}