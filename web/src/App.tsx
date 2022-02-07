import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import Home from './components/Home/Home';
import Fund from './components/Fund/Fund'
import About from './components/About/About'
import Coaches from './components/Coaches/Coaches';
import './App.scss'

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home/>} />
        <Route path="/fund" element={<Fund/>} />
        <Route path="/about" element={<About/>} />
        <Route path="/coaches" element={<Coaches/>} />
      </Routes>
      
    </Router>
  );
}

export default App;
