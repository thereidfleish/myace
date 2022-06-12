import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import ScrollToTop from './components/ScrollToTop'
import Header from './components/Header/Header'
import Footer from './components/Footer/Footer'
import Home from './components/Home/Home';
import ForgotPassword from './components/ForgotPassword/ForgotPassword'
import Privacy from './components/Privacy/Privacy'
import ContactUs from './components/ContactUs/ContactUs'
// import Coaches from './components/Coaches/Coaches';
import './App.scss'

function App() {
  return (
    <Router>
      <ScrollToTop>
        <Header />
        <Routes>
          <Route path="/" element={<Home/>} />
          <Route path="/privacy" element={<Privacy/>} />
          <Route path="/contact" element={<ContactUs/>} />
          <Route path="/forgotpassword" element={<ForgotPassword/>} />
        </Routes>
        <Footer />
      </ScrollToTop>
    </Router>
  );
}

export default App;
