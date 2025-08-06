import React, { useState, useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  IconButton,
  Chip,
  Avatar,
  List,
  ListItem,
  ListItemText,
  ListItemAvatar,
  Divider,
  Button,
  LinearProgress,
  Alert,
  Paper
} from '@mui/material';
import {
  Phone,
  LocationOn,
  Message,
  CameraAlt,
  Keyboard,
  ScreenShare,
  TrendingUp,
  Warning,
  CheckCircle,
  Error,
  Refresh,
  MoreVert,
  Visibility,
  VisibilityOff,
  Battery90,
  Wifi,
  SignalCellular4Bar
} from '@mui/icons-material';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useQuery } from 'react-query';
import { useSelector, useDispatch } from 'react-redux';
import { motion } from 'framer-motion';
import toast from 'react-hot-toast';

// API services
import { dashboardAPI } from '../../services/api';

// Redux actions
import { updateDevices, updateAlerts } from '../../store/slices/dashboardSlice';

// Components
import DeviceStatusCard from '../../components/Dashboard/DeviceStatusCard';
import ActivityTimeline from '../../components/Dashboard/ActivityTimeline';
import QuickActions from '../../components/Dashboard/QuickActions';
import AlertPanel from '../../components/Dashboard/AlertPanel';

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
);

// Fix for Leaflet markers
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl: require('leaflet/dist/images/marker-icon.png'),
  shadowUrl: require('leaflet/dist/images/marker-shadow.png'),
});

const Dashboard = () => {
  const dispatch = useDispatch();
  const { user } = useSelector((state) => state.auth);
  const { devices, alerts, isLoading } = useSelector((state) => state.dashboard);
  
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [autoRefresh, setAutoRefresh] = useState(true);

  // Fetch dashboard data
  const { data: dashboardData, refetch } = useQuery(
    'dashboard',
    dashboardAPI.getDashboardData,
    {
      refetchInterval: autoRefresh ? 30000 : false, // 30 seconds
      staleTime: 10000,
    }
  );

  // Activity data for charts
  const activityData = {
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    datasets: [
      {
        label: 'Calls',
        data: [12, 19, 3, 5, 2, 3, 7],
        borderColor: '#2196f3',
        backgroundColor: 'rgba(33, 150, 243, 0.1)',
        tension: 0.4,
      },
      {
        label: 'Messages',
        data: [25, 32, 15, 18, 22, 28, 35],
        borderColor: '#4caf50',
        backgroundColor: 'rgba(76, 175, 80, 0.1)',
        tension: 0.4,
      },
      {
        label: 'Location Updates',
        data: [8, 12, 6, 9, 11, 14, 16],
        borderColor: '#ff9800',
        backgroundColor: 'rgba(255, 152, 0, 0.1)',
        tension: 0.4,
      },
    ],
  };

  // App usage data
  const appUsageData = {
    labels: ['WhatsApp', 'Instagram', 'Facebook', 'YouTube', 'TikTok', 'Others'],
    datasets: [
      {
        data: [30, 25, 15, 12, 10, 8],
        backgroundColor: [
          '#25D366',
          '#E4405F',
          '#1877F2',
          '#FF0000',
          '#000000',
          '#6c757d',
        ],
        borderWidth: 2,
        borderColor: '#1a1a1a',
      },
    ],
  };

  // Device status data
  const deviceStatusData = {
    labels: ['Online', 'Offline', 'Error'],
    datasets: [
      {
        data: [3, 1, 0],
        backgroundColor: ['#4caf50', '#ff9800', '#f44336'],
        borderWidth: 0,
      },
    ],
  };

  const chartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top',
        labels: {
          color: '#ffffff',
        },
      },
    },
    scales: {
      x: {
        ticks: {
          color: '#b0b0b0',
        },
        grid: {
          color: 'rgba(255, 255, 255, 0.1)',
        },
      },
      y: {
        ticks: {
          color: '#b0b0b0',
        },
        grid: {
          color: 'rgba(255, 255, 255, 0.1)',
        },
      },
    },
  };

  // Quick stats cards
  const statsCards = [
    {
      title: 'Active Devices',
      value: devices?.filter(d => d.status === 'active').length || 0,
      total: devices?.length || 0,
      icon: <Phone />,
      color: '#4caf50',
      trend: '+2',
    },
    {
      title: 'Total Calls',
      value: dashboardData?.totalCalls || 0,
      icon: <Phone />,
      color: '#2196f3',
      trend: '+12%',
    },
    {
      title: 'Messages',
      value: dashboardData?.totalMessages || 0,
      icon: <Message />,
      color: '#ff9800',
      trend: '+8%',
    },
    {
      title: 'Location Updates',
      value: dashboardData?.locationUpdates || 0,
      icon: <LocationOn />,
      color: '#9c27b0',
      trend: '+15%',
    },
  ];

  // Recent activities
  const recentActivities = [
    {
      id: 1,
      type: 'call',
      device: 'iPhone 12',
      action: 'Incoming call from +1234567890',
      time: '2 minutes ago',
      status: 'completed',
    },
    {
      id: 2,
      type: 'message',
      device: 'Samsung Galaxy',
      action: 'New WhatsApp message',
      time: '5 minutes ago',
      status: 'unread',
    },
    {
      id: 3,
      type: 'location',
      device: 'iPhone 12',
      action: 'Location updated',
      time: '10 minutes ago',
      status: 'success',
    },
    {
      id: 4,
      type: 'app',
      device: 'Samsung Galaxy',
      action: 'Instagram opened',
      time: '15 minutes ago',
      status: 'active',
    },
  ];

  const handleDeviceSelect = (device) => {
    setSelectedDevice(device);
  };

  const handleRefresh = () => {
    refetch();
    toast.success('Dashboard refreshed');
  };

  const handleToggleAutoRefresh = () => {
    setAutoRefresh(!autoRefresh);
    toast.success(autoRefresh ? 'Auto-refresh disabled' : 'Auto-refresh enabled');
  };

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Box>
          <Typography variant="h4" sx={{ mb: 1 }}>
            Dashboard
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Welcome back, {user?.firstName}! Here's what's happening with your devices.
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={handleRefresh}
            disabled={isLoading}
          >
            Refresh
          </Button>
          <Button
            variant="outlined"
            startIcon={autoRefresh ? <VisibilityOff /> : <Visibility />}
            onClick={handleToggleAutoRefresh}
          >
            {autoRefresh ? 'Disable' : 'Enable'} Auto-refresh
          </Button>
        </Box>
      </Box>

      {/* Alerts */}
      {alerts?.length > 0 && (
        <Box sx={{ mb: 3 }}>
          <AlertPanel alerts={alerts} />
        </Box>
      )}

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        {statsCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <Box>
                      <Typography color="text.secondary" gutterBottom>
                        {card.title}
                      </Typography>
                      <Typography variant="h4" component="div">
                        {card.value}
                        {card.total && (
                          <Typography variant="body2" color="text.secondary" component="span">
                            /{card.total}
                          </Typography>
                        )}
                      </Typography>
                      <Chip
                        label={card.trend}
                        size="small"
                        color="success"
                        sx={{ mt: 1 }}
                      />
                    </Box>
                    <Avatar sx={{ bgcolor: card.color, width: 56, height: 56 }}>
                      {card.icon}
                    </Avatar>
                  </Box>
                </CardContent>
              </Card>
            </motion.div>
          </Grid>
        ))}
      </Grid>

      {/* Main Content Grid */}
      <Grid container spacing={3}>
        {/* Left Column */}
        <Grid item xs={12} lg={8}>
          {/* Activity Chart */}
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Activity Overview
              </Typography>
              <Box sx={{ height: 300 }}>
                <Line data={activityData} options={chartOptions} />
              </Box>
            </CardContent>
          </Card>

          {/* Device Status */}
          <Grid container spacing={3}>
            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Device Status
                  </Typography>
                  <Box sx={{ height: 200 }}>
                    <Doughnut data={deviceStatusData} options={chartOptions} />
                  </Box>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} md={6}>
              <Card>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    App Usage
                  </Typography>
                  <Box sx={{ height: 200 }}>
                    <Doughnut data={appUsageData} options={chartOptions} />
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Grid>

        {/* Right Column */}
        <Grid item xs={12} lg={4}>
          {/* Quick Actions */}
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Quick Actions
              </Typography>
              <QuickActions />
            </CardContent>
          </Card>

          {/* Recent Activity */}
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Activity
              </Typography>
              <List>
                {recentActivities.map((activity, index) => (
                  <React.Fragment key={activity.id}>
                    <ListItem alignItems="flex-start">
                      <ListItemAvatar>
                        <Avatar sx={{ bgcolor: activity.status === 'completed' ? '#4caf50' : '#ff9800' }}>
                          {activity.type === 'call' && <Phone />}
                          {activity.type === 'message' && <Message />}
                          {activity.type === 'location' && <LocationOn />}
                          {activity.type === 'app' && <ScreenShare />}
                        </Avatar>
                      </ListItemAvatar>
                      <ListItemText
                        primary={activity.action}
                        secondary={
                          <React.Fragment>
                            <Typography component="span" variant="body2" color="text.primary">
                              {activity.device}
                            </Typography>
                            {` — ${activity.time}`}
                          </React.Fragment>
                        }
                      />
                    </ListItem>
                    {index < recentActivities.length - 1 && <Divider variant="inset" component="li" />}
                  </React.Fragment>
                ))}
              </List>
            </CardContent>
          </Card>

          {/* Device Status Cards */}
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Device Status
              </Typography>
              {devices?.map((device) => (
                <DeviceStatusCard
                  key={device.id}
                  device={device}
                  selected={selectedDevice?.id === device.id}
                  onSelect={() => handleDeviceSelect(device)}
                />
              ))}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard; 