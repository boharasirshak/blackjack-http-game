import React from "react";
import { createRoot } from "react-dom/client";
import { createBrowserRouter, RouterProvider } from "react-router-dom";

import Dashboard from "./pages/Dashboard/Dashboard";
import ErrorPage from "./pages/ErrorPage";
import Game from "./pages/Game"; // bruh, wtf is this naming convention I just created
import Games from "./pages/Games/Games";
import Login from "./pages/Login/Login";
import PrivateRoute from "./pages/PrivateRoute";
import Signup from "./pages/Signup/Signup";

import App from "./App";

const router = createBrowserRouter([
  {
    path: "/",
    element: <App />,
    errorElement: <ErrorPage />,
  },
  {
    path: "/login",
    element: <Login />,
    errorElement: <ErrorPage />,
  },
  {
    path: "/signup",
    element: <Signup />,
    errorElement: <ErrorPage />,
  },
  {
    path: "/error",
    element: <ErrorPage />,
  },
  {
    path: "/dashboard",
    element: <PrivateRoute component={Dashboard} />,
    errorElement: <ErrorPage />,
  },
  {
    path: "/games",
    element: <PrivateRoute component={Games} />,
    errorElement: <ErrorPage />,
  },
  {
    path: "/game/:code",
    element: <PrivateRoute component={Game} />,
    errorElement: <ErrorPage />,
  },
]);

const node = document.getElementById("root") as HTMLElement;

createRoot(node).render(
  <RouterProvider router={router} />
);
