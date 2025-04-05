<!DOCTYPE html>
<html lang="en">
<body>

  <h1>🧠 MultiMind – Converse with a Chorus of AIs</h1>

  <div class="section">
    <p><strong>MultiMind</strong> is an AI-powered Flutter web application that takes chatting with AI to a whole new level. Instead of getting a single response to your prompt, you get <strong>multiple perspectives from multiple AI personas</strong>—all at once.</p>
    <p>Whether you’re brainstorming, seeking advice, learning something new, or just curious how different minds might interpret your question—<strong>MultiMind</strong> delivers diverse, insightful, and even surprising answers with every prompt.</p>
  </div>

  <h2>✨ Key Features</h2>
  <ul>
    <li>💬 <strong>One Prompt, Many Minds:</strong> Get responses from multiple AI models or personas in parallel.</li>
    <li>🧠 <strong>Powered by Multiple Free Models:</strong> Currently supports:
      <ul>
        <li><code>llama3.1:latest</code></li>
        <li><code>gemma2:9b</code></li>
        <li><code>mistral-nemo:latest</code></li>
      </ul>
    </li>
    <li>🎭 <strong>Diverse AI Personas:</strong> Each AI has its own style, tone, and way of thinking.</li>
    <li>⚡ <strong>Real-Time Chat Interface:</strong> Built with Flutter for a fast, responsive, and beautiful user experience.</li>
    <li>🌐 <strong>Web-Ready:</strong> Easily accessible through the browser—no installs needed.</li>
    <li>🧩 <strong>Modular Design:</strong> Easy to expand and plug in new models or personas.</li>
  </ul>

  <h2>🚀 Getting Started</h2>

  <div class="section">
    <h3>📦 Prerequisites</h3>
    <ul>
      <li>Flutter SDK installed (latest stable version recommended)</li>
      <li>Dart SDK</li>
      <li>An IDE like VS Code or Android Studio</li>
      <li>Internet connection (for fetching responses from AI APIs)</li>
    </ul>
  </div>

  <div class="section">
    <h3>🔧 Setup Instructions</h3>
    <ol>
      <li><strong>Clone the Repository:</strong>
        <pre><code>git clone https://github.com/yourusername/multimind.git
cd multimind</code></pre>
      </li>
      <li><strong>Install Dependencies:</strong>
        <pre><code>flutter pub get</code></pre>
      </li>
      <li><strong>Add API Keys:</strong>
        <ul>
          <li>Create a <code>.env</code> file or configure <code>api_keys.dart</code>.</li>
          <li>Add your API keys for the supported AI models (e.g., OpenRouter, Hugging Face, etc.).</li>
        </ul>
      </li>
      <li><strong>Run the App:</strong>
        <pre><code>flutter run -d chrome</code></pre>
      </li>
    </ol>
  </div>

  <h2>🛠️ How to Use</h2>
  <ul>
    <li>Open the app in your browser.</li>
    <li>Type a prompt in the chat input box.</li>
    <li>Hit send, and watch multiple AI models respond simultaneously.</li>
    <li>Scroll through the responses, compare insights, and interact with individual AIs if needed.</li>
  </ul>

  <h2>📌 Example Use Cases</h2>
  <ul>
    <li>🔍 Get multiple answers for a single query</li>
    <li>🧠 Brainstorm creatively with different thinking styles</li>
    <li>🗣️ Compare professional, casual, and humorous tones in one go</li>
    <li>📚 Use it as an educational tool to explore different viewpoints</li>
  </ul>

</body>
</html>
