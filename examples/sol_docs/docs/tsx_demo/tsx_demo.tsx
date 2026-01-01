// TSX Demo Component - demonstrates TSX SSR in Astra

export default function TsxDemo() {
  return (
    <div className="tsx-demo-component">
      <h2>TSX Demo Component</h2>
      <p>This component is rendered from a .tsx file!</p>
      <ul>
        <li>Written in TypeScript/JSX</li>
        <li>SSR via React renderToString</li>
        <li>Can use React hooks and components</li>
      </ul>
    </div>
  );
}
