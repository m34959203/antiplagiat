'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'

export default function Home() {
  const [text, setText] = useState('')
  const [isChecking, setIsChecking] = useState(false)

  const handleCheck = async () => {
    setIsChecking(true)
    // TODO: API call
    setTimeout(() => setIsChecking(false), 2000)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-blue-50">
      {/* Header */}
      <header className="border-b bg-white/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center space-x-2">
              <span className="text-2xl">🔍</span>
              <span className="text-xl font-bold text-gray-900">Antiplagiat</span>
            </div>
            <nav className="flex items-center space-x-6">
              <a href="#features" className="text-gray-600 hover:text-gray-900">Возможности</a>
              <a href="#pricing" className="text-gray-600 hover:text-gray-900">Цены</a>
              <button className="px-4 py-2 text-blue-600 hover:text-blue-700">Войти</button>
              <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                Регистрация
              </button>
            </nav>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-20 pb-16">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="text-center mb-12"
        >
          <h1 className="text-5xl md:text-6xl font-bold text-gray-900 mb-6">
            Проверьте текст на уникальность
            <br />
            <span className="text-blue-600">за 30 секунд</span>
          </h1>
          <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
            AI-powered детекция плагиата с точностью до 94%.
            Поддержка русского и английского языков.
          </p>
        </motion.div>

        {/* Check Form */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="max-w-3xl mx-auto"
        >
          <div className="bg-white rounded-2xl shadow-2xl p-8">
            <textarea
              value={text}
              onChange={(e) => setText(e.target.value)}
              placeholder="Вставьте текст для проверки (минимум 100 символов)..."
              className="w-full h-48 p-4 border border-gray-300 rounded-lg resize-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            
            <div className="flex items-center justify-between mt-4">
              <div className="text-sm text-gray-500">
                {text.length} символов • {text.split(/\s+/).filter(Boolean).length} слов
              </div>
              <button
                onClick={handleCheck}
                disabled={text.length < 100 || isChecking}
                className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isChecking ? (
                  <>
                    <svg className="animate-spin h-5 w-5 mr-2 inline" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                    </svg>
                    Проверяем...
                  </>
                ) : (
                  <>🚀 Проверить бесплатно</>
                )}
              </button>
            </div>

            <div className="flex items-center justify-center space-x-6 mt-6 text-sm text-gray-600">
              <span className="flex items-center">
                <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                Без регистрации
              </span>
              <span className="flex items-center">
                <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                3 проверки в день
              </span>
            </div>
          </div>
        </motion.div>
      </section>

      {/* Social Proof */}
      <section className="bg-white py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              className="card"
            >
              <div className="text-4xl font-bold text-blue-600 mb-2">12,450+</div>
              <div className="text-gray-600">Проверок выполнено</div>
            </motion.div>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="card"
            >
              <div className="text-4xl font-bold text-green-600 mb-2">94.2%</div>
              <div className="text-gray-600">Точность детекции</div>
            </motion.div>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
              className="card"
            >
              <div className="text-4xl font-bold text-purple-600 mb-2">&lt;15 сек</div>
              <div className="text-gray-600">Среднее время проверки</div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">Как это работает</h2>
            <p className="text-xl text-gray-600">Три простых шага до результата</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
            {[
              { icon: '📄', title: 'Загрузите текст', desc: 'Скопируйте текст или загрузите документ (DOCX, PDF, TXT)' },
              { icon: '🔍', title: 'AI-анализ', desc: 'Наши ML-модели проверят текст по миллионам источников' },
              { icon: '📊', title: 'Получите отчёт', desc: 'Подробный отчёт с процентом уникальности и источниками' }
            ].map((feature, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.5, delay: i * 0.1 }}
                className="text-center"
              >
                <div className="text-6xl mb-4">{feature.icon}</div>
                <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
                <p className="text-gray-600">{feature.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-gray-300 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div>
              <div className="text-white text-xl font-bold mb-4">Antiplagiat</div>
              <p className="text-sm">Профессиональная проверка текстов на уникальность</p>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Продукт</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="#" className="hover:text-white">Возможности</a></li>
                <li><a href="#" className="hover:text-white">Цены</a></li>
                <li><a href="#" className="hover:text-white">API</a></li>
              </ul>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Компания</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="#" className="hover:text-white">О нас</a></li>
                <li><a href="#" className="hover:text-white">Блог</a></li>
                <li><a href="#" className="hover:text-white">Контакты</a></li>
              </ul>
            </div>
            <div>
              <h4 className="text-white font-semibold mb-4">Поддержка</h4>
              <ul className="space-y-2 text-sm">
                <li><a href="#" className="hover:text-white">Справка</a></li>
                <li><a href="#" className="hover:text-white">Документация</a></li>
                <li><a href="#" className="hover:text-white">Политика</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 mt-8 pt-8 text-sm text-center">
            © 2025 Antiplagiat. Powered by AI & TypeScript.
          </div>
        </div>
      </footer>
    </div>
  )
}