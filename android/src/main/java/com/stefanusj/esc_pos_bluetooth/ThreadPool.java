package com.stefanusj.esc_pos_bluetooth;

import android.util.Log;

import java.util.ArrayDeque;
import java.util.concurrent.*;


public class ThreadPool {

    private Runnable mActive;

    private static ThreadPool threadPool;
    /**
     * java线程池
     */
    private ThreadPoolExecutor threadPoolExecutor;

    /**
     * 系统最大可用线程
     */
    private final static int CPU_AVAILABLE = Runtime.getRuntime().availableProcessors();

    /**
     * 最大线程数
     */
    private final static int MAX_POOL_COUNTS = CPU_AVAILABLE * 2 + 1;

    /**
     * 线程存活时间
     */
    private final static long AVAILABLE = 1L;

    /**
     * 核心线程数
     */
    private final static int CORE_POOL_SIZE = CPU_AVAILABLE + 1;

    /**
     * 线程池缓存队列
     */
    private BlockingQueue<Runnable> mWorkQueue = new ArrayBlockingQueue<>(CORE_POOL_SIZE);

    private ArrayDeque<Runnable> mArrayDeque = new ArrayDeque<>();

    private ThreadFactory threadFactory = new ThreadFactoryBuilder("ThreadPool");

    private ThreadPool() {
        threadPoolExecutor = new ThreadPoolExecutor(CORE_POOL_SIZE, MAX_POOL_COUNTS, AVAILABLE, TimeUnit.SECONDS, mWorkQueue, threadFactory);
    }

    public static ThreadPool getInstantiation() {
        if (threadPool == null) {
            threadPool = new ThreadPool();
        }
        return threadPool;
    }

    public void addParallelTask(Runnable runnable) { //并行线程
        if (runnable == null) {
            throw new NullPointerException("addTask(Runnable runnable)传入参数为空");
        }
        if (threadPoolExecutor.getActiveCount() < MAX_POOL_COUNTS) {
            Log.i("Lee", "目前有" + threadPoolExecutor.getActiveCount() + "个线程正在进行中,有" + mWorkQueue.size() + "个任务正在排队");
            synchronized (this) {
                threadPoolExecutor.execute(runnable);
            }
        }
    }

    public synchronized void addSerialTask(final Runnable r) { //串行线程
        if (r == null) {
            throw new NullPointerException("addTask(Runnable runnable)传入参数为空");
        }
        mArrayDeque.offer(new Runnable() {
            @Override
            public void run() {
                try {
                    r.run();
                } finally {
                    scheduleNext();
                }
            }
        });
        // 第一次入队列时mActivie为空，因此需要手动调用scheduleNext方法
        if (mActive == null) {
            scheduleNext();
        }
    }

    private void scheduleNext() {
        if ((mActive = mArrayDeque.poll()) != null) {
            threadPoolExecutor.execute(mActive);
        }
    }

    public void stopThreadPool() {
        if (threadPoolExecutor != null) {
            threadPoolExecutor.shutdown();
            threadPoolExecutor = null;
            threadPool = null;
        }
    }
}