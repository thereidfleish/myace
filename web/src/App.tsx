import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Header from './components/Header/Header'
import Home from './components/Home/Home';
import ForgotPassword from './components/ForgotPassword/ForgotPassword'
// import Coaches from './components/Coaches/Coaches';
import './App.scss'

function App() {
return (
    <Router>
      <div>
        <Header />
      </div>
      <Routes>
        <Route path="/" element={<Home/>} />
        <Route path="/forgotpassword" element={<ForgotPassword/>} />
      </Routes>
    </Router>
  );
}

export default App;
