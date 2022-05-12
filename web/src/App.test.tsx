import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders meet the team section', () => {
  render(<App />);
  const header = screen.getByText(/Meet the team/i);
  expect(header).toBeInTheDocument();
});
