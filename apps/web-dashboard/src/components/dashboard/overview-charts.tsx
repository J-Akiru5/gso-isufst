'use client'

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts'

interface OverviewChartsProps {
  monthlyData: { month: string; requests: number }[]
  utilizationData: { name: string; value: number; color: string }[]
}

export function OverviewCharts({ monthlyData, utilizationData }: OverviewChartsProps) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
      {/* Maintenance Requests Chart */}
      <div className="bg-card rounded-xl border border-border p-6">
        <div className="mb-4">
          <h2 className="text-lg font-bold">Maintenance Requests</h2>
          <p className="text-sm text-muted-foreground">Requests over the last 6 months</p>
        </div>
        <div className="h-[300px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={monthlyData}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="currentColor" className="text-border" />
              <XAxis 
                dataKey="month" 
                axisLine={false}
                tickLine={false}
                tick={{ fill: 'currentColor' }}
                className="text-muted-foreground text-xs"
              />
              <YAxis 
                axisLine={false}
                tickLine={false}
                tick={{ fill: 'currentColor' }}
                className="text-muted-foreground text-xs"
              />
              <Tooltip
                cursor={{ fill: 'var(--color-primary)', opacity: 0.1 }}
                contentStyle={{
                  backgroundColor: 'var(--color-card)',
                  borderColor: 'var(--color-border)',
                  borderRadius: '8px',
                  color: 'var(--color-foreground)',
                }}
              />
              <Bar dataKey="requests" fill="#0352bc" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Equipment Utilization Chart */}
      <div className="bg-card rounded-xl border border-border p-6">
        <div className="mb-4">
          <h2 className="text-lg font-bold">Equipment Utilization</h2>
          <p className="text-sm text-muted-foreground">Available vs. Borrowed items</p>
        </div>
        <div className="h-[300px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie
                data={utilizationData}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={100}
                paddingAngle={5}
                dataKey="value"
              >
                {utilizationData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{
                  backgroundColor: 'var(--color-card)',
                  borderColor: 'var(--color-border)',
                  borderRadius: '8px',
                  color: 'var(--color-foreground)',
                }}
              />
              <Legend verticalAlign="bottom" height={36} wrapperStyle={{ color: 'var(--color-foreground)' }} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )
}
