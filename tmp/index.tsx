import { useState, useEffect } from 'react'
import {
  Box,
  Paper,
  Typography,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Alert,
  Link,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Tooltip,
  LinearProgress,
  Stack,
  Divider,
  RadioGroup,
  FormControlLabel,
  Radio,
  FormLabel
} from '@mui/material'
import { DateTimePicker } from '@mui/x-date-pickers/DateTimePicker'
import {
  Delete as DeleteIcon,
  Refresh as RefreshIcon,
  Add as AddIcon,
  Clear as ClearIcon,
  Search as SearchIcon,
  OpenInNew as OpenInNewIcon,
  Edit as EditIcon,
  CheckCircle,
  HourglassEmpty,
  Sync,
  Error as ErrorIcon,
  ContentCopy as ContentCopyIcon,
  FilterList as FilterListIcon,
  PublicOutlined,
  LockOutlined,
  Public as PublicIcon,
  Lock as LockIcon
} from '@mui/icons-material'
import { getTasks, createTask, deleteTask, retryTask, getTaskDetail, updateTask, downloadFile } from '@/services/task'
import type { Task } from '@/types/task'
import dayjs from 'dayjs';

// 添加复制函数
function copyToClipboard(text: string | undefined) {
  if (!text) return; // 如果文本为空则直接返回
  
  navigator.clipboard.writeText(text).then(() => {
    // 使用 Snackbar 显示提示
    const snackbar = document.createElement('div');
    snackbar.style.cssText = `
      position: fixed;
      bottom: 20px;
      right: 20px;
      background: #333;
      color: white;
      padding: 10px 20px;
      border-radius: 4px;
      z-index: 9999;
      animation: fadeIn 0.3s, fadeOut 0.3s 2.7s;
    `;
    snackbar.textContent = '复制成功!';
    document.body.appendChild(snackbar);
    setTimeout(() => snackbar.remove(), 3000);
  }).catch(() => {
    const snackbar = document.createElement('div');
    snackbar.style.cssText = `
      position: fixed;
      bottom: 20px;
      right: 20px;
      background: #d32f2f;
      color: white;
      padding: 10px 20px;
      border-radius: 4px;
      z-index: 9999;
      animation: fadeIn 0.3s, fadeOut 0.3s 2.7s;
    `;
    snackbar.textContent = '复制失败,请重试';
    document.body.appendChild(snackbar);
    setTimeout(() => snackbar.remove(), 3000);
  });
}

// 在 TasksPage 组件中添加 URL 截断函数
function truncateText(text: string, maxLength: number = 20) {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength) + '...';
}

// 更新进度条组件
function TaskProgress({ task }: { task: Task }) {
  if (task.status === 'completed') return null;
  
  const totalProgress = task.current_step_index !== undefined && task.total_steps 
    ? Math.round(((task.current_step_index + 1) / task.total_steps) * 100)
    : 0;
  
  return (
    <Box sx={{ width: '100%' }}>
      <Box sx={{ 
        display: 'flex', 
        justifyContent: 'space-between',
        alignItems: 'center',
        mb: 0.5
      }}>
        <Typography variant="caption" color="textSecondary" noWrap sx={{ maxWidth: '70%' }}>
          {truncateText(task.current_step || '准备中', 12)}
        </Typography>
        <Typography variant="caption" color="textSecondary">
          {totalProgress}%
        </Typography>
      </Box>

      <LinearProgress 
        variant="determinate" 
        value={totalProgress}
        sx={{ height: 4, borderRadius: 2 }}
      />

      {task.progress_message && (
        <Tooltip title={task.progress_message}>
          <Typography 
            variant="caption" 
            color="textSecondary"
            onClick={() => task.progress_message && copyToClipboard(task.progress_message)}
            sx={{ 
              display: 'block',
              mt: 0.5,
              cursor: 'pointer',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
              '&:hover': { color: 'primary.main' }
            }}
          >
            {truncateText(task.progress_message || '', 12)}
          </Typography>
        </Tooltip>
      )}
    </Box>
  );
}

// 状态图标配置
const STATUS_CONFIG = {
  pending: { 
    icon: <HourglassEmpty fontSize="small" />,
    color: '#909399' // 灰色
  },
  processing: { 
    icon: <Sync fontSize="small" />,
    color: '#409EFF' // 蓝色
  },
  completed: { 
    icon: <CheckCircle fontSize="small" />,
    color: '#67C23A' // 绿色
  },
  failed: { 
    icon: <ErrorIcon fontSize="small" />,
    color: '#F56C6C' // 红色
  }
};

// 状态显示组件
function getStatusChip(task: Task) {
  const status = STATUS_CONFIG[task.status];
  return (
    <Tooltip title={task.status}>
      <Box sx={{ color: status.color }}>
        {status.icon}
      </Box>
    </Tooltip>
  );
}

// 添加常量定义
const BUTTON_STYLES = {
  height: 36,
  minWidth: 88,
} as const;

const INPUT_STYLES = {
  width: 200,
} as const;

// 编辑对话框组件
function EditTaskDialog({ 
  open, 
  task, 
  onClose, 
  onSave 
}: { 
  open: boolean;
  task: Task | null;
  onClose: () => void;
  onSave: (title: string, isPublic: boolean) => void;
}) {
  const [title, setTitle] = useState('')
  const [isPublic, setIsPublic] = useState(false)

  // 当对话框打开时，初始化表单数据
  useEffect(() => {
    if (task && open) {
      setTitle(task.title || '')
      setIsPublic(task.is_public)
    }
  }, [task, open])

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>编辑任务</DialogTitle>
      <DialogContent>
        <Stack spacing={3} sx={{ mt: 2 }}>
          <TextField
            label="标题"
            fullWidth
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
          
          <FormControl>
            <FormLabel>访问权限</FormLabel>
            <RadioGroup
              row
              value={isPublic}
              onChange={(e) => setIsPublic(e.target.value === 'true')}
            >
              <FormControlLabel 
                value={true}
                control={<Radio />}
                label={
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <PublicOutlined color={isPublic ? "primary" : "disabled"} />
                    <Typography>公开</Typography>
                    <Typography variant="caption" color="text.secondary">
                      （所有人可见）
                    </Typography>
                  </Box>
                }
              />
              <FormControlLabel
                value={false}
                control={<Radio />}
                label={
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <LockOutlined color={!isPublic ? "primary" : "disabled"} />
                    <Typography>私有</Typography>
                    <Typography variant="caption" color="text.secondary">
                      （仅自己可见）
                    </Typography>
                  </Box>
                }
              />
            </RadioGroup>
          </FormControl>
        </Stack>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>取消</Button>
        <Button 
          variant="contained"
          onClick={() => onSave(title, isPublic)}
        >
          保存
        </Button>
      </DialogActions>
    </Dialog>
  )
}

export function TasksPage() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [total, setTotal] = useState(0)
  const [page, setPage] = useState(0)
  const [rowsPerPage] = useState(10)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [createDialogOpen, setCreateDialogOpen] = useState(false)
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [selectedTask, setSelectedTask] = useState<Task | null>(null)
  const [newTaskUrl, setNewTaskUrl] = useState('')
  const [status, setStatus] = useState<string>('all')
  const [visibility, setVisibility] = useState<string>('all')
  const [startDate, setStartDate] = useState<number | null>(() => {
    // 默认为一个月前
    const date = new Date()
    date.setMonth(date.getMonth() - 1)
    date.setHours(0, 0, 0, 0)
    return date.getTime()
  })
  const [endDate, setEndDate] = useState<number | null>(() => {
    // 默认为今天的23:59:59
    const date = new Date()
    date.setHours(23, 59, 59, 999)
    return date.getTime()
  })
  const [titleKeyword, setTitleKeyword] = useState('')
  const [urlKeyword, setUrlKeyword] = useState('')
  const [editDialogOpen, setEditDialogOpen] = useState(false)
  const [editingTask, setEditingTask] = useState<Task | null>(null)
  const [newTaskVisibility, setNewTaskVisibility] = useState(false)

  // 获取任务列表
  const fetchTasks = async () => {
    setLoading(true)
    setError('')
    try {
      const params: Record<string, any> = {
        offset: page * rowsPerPage,
        limit: rowsPerPage,
        title_keyword: titleKeyword,
        url_keyword: urlKeyword
      }
      
      if (startDate) params.start_date = startDate
      if (endDate) params.end_date = endDate
      if (status !== 'all') params.status = status
      if (visibility === 'public') params.is_public = true
      if (visibility === 'private') params.is_public = false

      const response = await getTasks(params)
      setTasks(response.items)
      setTotal(response.total)
    } catch (err: any) {
      setError(err.response?.data?.detail || '获取任务列表失败')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchTasks()
  }, [page, rowsPerPage, status, startDate, endDate, visibility])

  // 创建任务
  const handleCreateTask = async () => {
    try {
      await createTask({
        url: newTaskUrl,
        is_public: newTaskVisibility
      })
      setCreateDialogOpen(false)
      setNewTaskUrl('')
      setNewTaskVisibility(false)
      fetchTasks()
    } catch (err: any) {
      setError(err.response?.data?.detail || '创建任务失败')
    }
  }

  // 删除任务
  const handleDeleteTask = async () => {
    if (!selectedTask) return
    try {
      await deleteTask(selectedTask.taskId)
      setDeleteDialogOpen(false)
      fetchTasks()
    } catch (err: any) {
      setError(err.response?.data?.detail || '删除任务失败')
    }
  }

  // 重试任务
  const handleRetryTask = async (task: Task) => {
    try {
      await retryTask(task.taskId)
      fetchTasks()
    } catch (err: any) {
      setError(err.response?.data?.detail || '重试任务失败')
    }
  }

  // 添加滤器重置函数
  const handleResetFilters = () => {
    setStatus('all')
    setVisibility('all')
    setStartDate(() => {
      const date = new Date()
      date.setMonth(date.getMonth() - 1)
      date.setHours(0, 0, 0, 0)
      return date.getTime()
    })
    setEndDate(() => {
      const date = new Date()
      date.setHours(23, 59, 59, 999)
      return date.getTime()
    })
    setTitleKeyword('')
    setUrlKeyword('')
    setPage(0)
  }

  // 定期更新未完成任务的状态
  useEffect(() => {
    const updateInProgressTasks = async () => {
      const updatedTasks = [...tasks]
      let needRefresh = false

      for (const task of updatedTasks) {
        if (task.status !== 'completed' && task.status !== 'failed') {
          try {
            const response = await getTaskDetail(task.taskId)
            const index = updatedTasks.findIndex(t => t.taskId === task.taskId)
            if (index !== -1) {
              updatedTasks[index] = response
              if (response.status === 'completed' || response.status === 'failed') {
                needRefresh = true
              }
            }
          } catch (err) {
            console.error(`Failed to update task ${task.taskId}:`, err)
          }
        }
      }

      if (needRefresh) {
        fetchTasks()
      } else {
        setTasks(updatedTasks)
      }
    }

    const intervalId = setInterval(updateInProgressTasks, 5000)
    return () => clearInterval(intervalId)
  }, [tasks])

  // 编辑任务
  const handleEditTask = async (title: string, isPublic: boolean) => {
    if (!editingTask) return
    try {
      await updateTask(editingTask.taskId, {
        title,
        is_public: isPublic
      })
      setEditDialogOpen(false)
      fetchTasks()
    } catch (err: any) {
      setError(err.response?.data?.detail || '更新任务失败')
    }
  }

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h5" sx={{ mb: 3 }}>任务管理</Typography>
      
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Paper sx={{ p: 3, mb: 3 }}>
        {/* 查询条件区域 */}
        <Box sx={{ mb: 2 }}>
          {/* 第一栏：筛选条件 */}
          <Box sx={{ 
            display: 'flex',
            flexWrap: 'wrap',
            alignItems: 'center',
            gap: 1,
            mb: 1
          }}>
            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>状态</InputLabel>
              <Select
                value={status}
                onChange={(e) => setStatus(e.target.value)}
                label="状态"
              >
                <MenuItem value="all">全部</MenuItem>
                <MenuItem value="pending">等待中</MenuItem>
                <MenuItem value="processing">处理中</MenuItem>
                <MenuItem value="completed">已完成</MenuItem>
                <MenuItem value="failed">失败</MenuItem>
              </Select>
            </FormControl>

            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>公开性</InputLabel>
              <Select
                value={visibility}
                onChange={(e) => setVisibility(e.target.value)}
                label="公开性"
              >
                <MenuItem value="all">全部</MenuItem>
                <MenuItem value="public">仅看公开</MenuItem>
                <MenuItem value="private">仅看私有</MenuItem>
              </Select>
            </FormControl>

            <TextField
              size="small"
              label="URL"
              value={urlKeyword}
              onChange={(e) => setUrlKeyword(e.target.value)}
              sx={{ width: 150 }}
            />

            <TextField
              size="small"
              label="标题"
              value={titleKeyword}
              onChange={(e) => setTitleKeyword(e.target.value)}
              sx={{ width: 150 }}
            />

            <DateTimePicker
              label="开始时间"
              value={startDate ? dayjs(startDate) : null}
              onChange={(date) => setStartDate(date ? date.valueOf() : null)}
              slotProps={{ 
                textField: { 
                  size: 'small',
                  sx: { width: 150 }
                } 
              }}
            />

            <DateTimePicker
              label="结束时间"
              value={endDate ? dayjs(endDate) : null}
              onChange={(date) => setEndDate(date ? date.valueOf() : null)}
              slotProps={{ 
                textField: { 
                  size: 'small',
                  sx: { width: 150 }
                } 
              }}
            />

            <Button
              variant="outlined"
              onClick={handleResetFilters}
              startIcon={<ClearIcon />}
              sx={{ minWidth: 80, ml: 'auto' }} // 右对齐
            >
              重置
            </Button>
          </Box>

          {/* 第二栏：操作按钮 */}
          <Box sx={{ 
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            gap: 1
          }}>
            <Button
              variant="contained"
              color="primary"
              startIcon={<AddIcon />}
              onClick={() => setCreateDialogOpen(true)}
              sx={{ minWidth: 100 }}
            >
              创建播客
            </Button>

            <Button
              variant="contained"
              onClick={fetchTasks}
              startIcon={<SearchIcon />}
              sx={{ minWidth: 80, ml: 'auto' }} // 右对齐
            >
              查询
            </Button>
          </Box>
        </Box>
      </Paper>

      <TableContainer component={Paper}>
        <Table size="small" sx={{ tableLayout: 'fixed' }}>
          <TableHead>
            <TableRow>
              <TableCell width="4%">ID</TableCell>
              <TableCell width="4%">URL</TableCell>
              <TableCell width="32%">标题</TableCell>
              <TableCell width="5%" align="center">状态</TableCell>
              <TableCell width="25%">进度</TableCell>
              <TableCell width="12%" align="center">音频/字幕</TableCell>
              <TableCell width="10%" align="center">创建时间</TableCell>
              <TableCell width="8%" align="center">操作</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {tasks.map((task) => (
              <TableRow key={task.taskId} hover>
                {/* ID和URL列紧凑布局 */}
                <TableCell sx={{ pr: 0 }}> {/* 移除右边距 */}
                  <Tooltip title={`点击复制: ${task.taskId}`}>
                    <IconButton 
                      size="small" 
                      onClick={() => copyToClipboard(task.taskId)}
                    >
                      <ContentCopyIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                </TableCell>
                <TableCell sx={{ pl: 0 }}> {/* 移除左边距 */}
                  <Stack direction="row" spacing={0.5}>
                    <Tooltip title={`点击复制: ${task.url}`}>
                      <IconButton 
                        size="small" 
                        onClick={() => copyToClipboard(task.url)}
                      >
                        <ContentCopyIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="在新窗口打开">
                      <IconButton 
                        size="small" 
                        onClick={() => window.open(task.url)}
                      >
                        <OpenInNewIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </Stack>
                </TableCell>

                {/* 标题列 */}
                <TableCell>
                  <Tooltip title={task.title || '-'}>
                    <Typography noWrap>
                      {truncateText(task.title || '-', 30)}
                    </Typography>
                  </Tooltip>
                </TableCell>

                {/* 状态列 */}
                <TableCell align="center">
                  {getStatusChip(task)}
                </TableCell>

                {/* 进度列 */}
                <TableCell>
                  <TaskProgress task={task} />
                </TableCell>

                {/* 音频/字幕列 */}
                <TableCell align="center">
                  <Stack 
                    direction="row" 
                    spacing={1} 
                    justifyContent="center"
                    divider={<Divider orientation="vertical" flexItem />}
                  >
                    <Stack direction="row" spacing={0.5}>
                      {task.audioUrlCn && (
                        <Link 
                          component="button"
                          onClick={() => downloadFile(task.taskId, task.audioUrlCn!)}
                          sx={{ cursor: 'pointer' }}
                        >
                          中
                        </Link>
                      )}
                      {task.audioUrlEn && (
                        <Link 
                          component="button"
                          onClick={() => downloadFile(task.taskId, task.audioUrlEn!)}
                          sx={{ cursor: 'pointer' }}
                        >
                          英
                        </Link>
                      )}
                    </Stack>
                    <Stack direction="row" spacing={0.5}>
                      {task.subtitleUrlCn && (
                        <Link 
                          component="button"
                          onClick={() => downloadFile(task.taskId, task.subtitleUrlCn!)}
                          sx={{ cursor: 'pointer' }}
                        >
                          中
                        </Link>
                      )}
                      {task.subtitleUrlEn && (
                        <Link 
                          component="button"
                          onClick={() => downloadFile(task.taskId, task.subtitleUrlEn!)}
                          sx={{ cursor: 'pointer' }}
                        >
                          英
                        </Link>
                      )}
                    </Stack>
                  </Stack>
                </TableCell>

                {/* 创建时间列 */}
                <TableCell align="center">
                  <Stack>
                    <Typography variant="caption" sx={{ fontFamily: 'monospace' }}>
                      {dayjs(task.createdAt).format('YYYY-MM-DD')}
                    </Typography>
                    <Typography variant="caption" sx={{ fontFamily: 'monospace' }}>
                      {dayjs(task.createdAt).format('HH:mm:ss')}
                    </Typography>
                  </Stack>
                </TableCell>

                {/* 操作列 */}
                <TableCell align="center">
                  <Stack direction="row" spacing={0.5} justifyContent="center">
                    <IconButton
                      size="small"
                      onClick={() => {
                        setEditingTask(task);
                        setEditDialogOpen(true);
                      }}
                    >
                      <EditIcon fontSize="small" />
                    </IconButton>
                    {task.status === 'failed' && (
                      <IconButton
                        size="small"
                        onClick={() => handleRetryTask(task)}
                        color="warning"
                      >
                        <RefreshIcon fontSize="small" />
                      </IconButton>
                    )}
                    <IconButton
                      size="small"
                      onClick={() => {
                        setSelectedTask(task);
                        setDeleteDialogOpen(true);
                      }}
                      color="error"
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </Stack>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* 创建任务对话框 */}
      <Dialog
        open={createDialogOpen}
        onClose={() => setCreateDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>创建新任务</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            margin="dense"
            label="URL"
            fullWidth
            value={newTaskUrl}
            onChange={(e) => setNewTaskUrl(e.target.value)}
            helperText="输入要处理的文章URL"
          />
          <Box sx={{ mt: 2 }}>
            <Button
              variant={newTaskVisibility ? "contained" : "outlined"}
              onClick={() => setNewTaskVisibility(!newTaskVisibility)}
            >
              {newTaskVisibility ? "公开" : "私有"}
            </Button>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateDialogOpen(false)}>取消</Button>
          <Button onClick={handleCreateTask} variant="contained">
            创建
          </Button>
        </DialogActions>
      </Dialog>

      {/* 删除确认对话框 */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
      >
        <DialogTitle>确认删除</DialogTitle>
        <DialogContent>
          确定要删除此任务吗？此操作不可恢复。
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>取消</Button>
          <Button onClick={handleDeleteTask} color="error">
            删除
          </Button>
        </DialogActions>
      </Dialog>

      {/* 编辑任务对话框 */}
      <EditTaskDialog
        open={editDialogOpen}
        task={editingTask}
        onClose={() => setEditDialogOpen(false)}
        onSave={handleEditTask}
      />
    </Box>
  )
}

// 搜索栏中的公开/私有过滤按钮
function PublicFilterButton({ value, onChange }: { 
  value: boolean | null; 
  onChange: (value: boolean | null) => void;
}) {
  const getButtonState = () => {
    if (value === null) return '全部'
    return value ? '仅看公开' : '仅看私有'
  }

  const getButtonColor = () => {
    if (value === null) return 'inherit'
    return 'primary'
  }

  const handleClick = () => {
    if (value === null) onChange(true)
    else if (value === true) onChange(false)
    else onChange(null)
  }

  return (
    <Button
      variant={value === null ? 'outlined' : 'contained'}
      onClick={handleClick}
      startIcon={value === null ? <FilterListIcon /> : value ? <PublicIcon /> : <LockIcon />}
      color={getButtonColor()}
    >
      {getButtonState()}
    </Button>
  )
}
