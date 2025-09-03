defmodule EmailToolsWeb.LandingLive do
  use EmailToolsWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:connected?, false)}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 py-16">
      <div class="text-center">
        <h1 class="text-4xl font-bold text-gray-900 mb-6">
          Welcome to Email Coach
        </h1>
        <p class="text-xl text-gray-600 mb-8">
          Master your inbox with personalized email management coaching
        </p>
        <div class="space-x-4">
          <.link
            navigate={~p"/users/register"}
            class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          >
            Get Started
          </.link>
          <.link
            navigate={~p"/users/log_in"}
            class="bg-gray-600 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded"
          >
            Log In
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
