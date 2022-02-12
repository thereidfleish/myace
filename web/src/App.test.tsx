import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders fund button link', () => {
  render(<App />);
  const linkElement = screen.getByText(/fund/i);
  expect(linkElement).toBeInTheDocument();
});
