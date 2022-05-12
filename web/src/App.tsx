import { BrowserRouter as Router } from 'react-router-dom'
import Header from './components/Header/Header'
import Home from './components/Home/Home';
import Timeline from './components/Timeline/Timeline'
import Fund from './components/Fund/Fund'
import About from './components/About/About'
// import Coaches from './components/Coaches/Coaches';
import Alpha from './components/Alpha/Alpha'
import './App.scss'

function App() {
return (
    <Router>
      <div>
        <Header />
        <Home />
        <Timeline />
        <About />
        {/* <Coaches /> */}
        <Fund />
        <Alpha />
      </div>
    </Router>
  );
}

export default App;
