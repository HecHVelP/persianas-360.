import { useMemo, useState } from 'react'
import {
  Activity, ArrowRight, Bell, Check, ChevronRight, ClipboardCheck,
  Clock3, FileText, Home, ImagePlus, Menu, Plus, Search, Settings,
  ShieldCheck, SlidersHorizontal, Users, Wrench, X
} from 'lucide-react'

type CheckStatus = 'Pendiente' | 'Conforme' | 'Incidencia' | 'No aplica'
type CheckItem = { id: number; title: string; detail: string; status: CheckStatus }

const initialChecks: CheckItem[] = [
  { id: 1, title: 'Estado general del paño', detail: 'Deformaciones, golpes, grietas y desgaste visible.', status: 'Pendiente' },
  { id: 2, title: 'Integridad de las lamas', detail: 'Uniones, tapones, lama terminal y alineación.', status: 'Pendiente' },
  { id: 3, title: 'Guías laterales', detail: 'Fijación, deformaciones, suciedad y marcas de roce.', status: 'Pendiente' },
  { id: 4, title: 'Cajón y tapas', detail: 'Integridad, fijación y señales de humedad.', status: 'Pendiente' },
  { id: 5, title: 'Eje y soportes', detail: 'Inspección visual; desmontaje solo con procedimiento seguro.', status: 'Pendiente' },
  { id: 6, title: 'Sistema de accionamiento', detail: 'Identificar cinta, torno, manivela o motor.', status: 'Pendiente' },
  { id: 7, title: 'Prueba funcional controlada', detail: 'Recorrido, suavidad, ruidos y respuesta.', status: 'Pendiente' },
]

const modules = ['Identificación', 'Inspección visual', 'Componentes', 'Accionamiento', 'Prueba funcional', 'Diagnóstico']
const nav = [
  { label: 'Resumen', icon: Home },
  { label: 'Intervenciones', icon: ClipboardCheck },
  { label: 'Clientes', icon: Users },
  { label: 'Informes', icon: FileText },
]

function App() {
  const [active, setActive] = useState('Resumen')
  const [checks, setChecks] = useState(initialChecks)
  const [query, setQuery] = useState('')
  const [showWizard, setShowWizard] = useState(false)
  const [step, setStep] = useState(0)
  const [mobileNav, setMobileNav] = useState(false)
  const done = checks.filter(c => c.status !== 'Pendiente').length
  const progress = Math.round((done / checks.length) * 100)
  const filtered = useMemo(() => ['Persiana salón · PRS-0001', 'Persiana dormitorio · PRS-0002', 'Persiana cocina · PRS-0003'].filter(x => x.toLowerCase().includes(query.toLowerCase())), [query])

  function updateStatus(id: number, status: CheckStatus) {
    setChecks(current => current.map(item => item.id === id ? { ...item, status } : item))
  }

  return (
    <div className="app-shell">
      <aside className={`sidebar ${mobileNav ? 'open' : ''}`}>
        <div className="brand">
          <div className="brand-mark"><Wrench size={19} /></div>
          <div><strong>Persianas<span>360</span></strong><small>FIELD OPERATIONS</small></div>
          <button className="icon-button mobile-close" onClick={() => setMobileNav(false)} aria-label="Cerrar menú"><X size={18}/></button>
        </div>
        <div className="workspace-label">ESPACIO DE TRABAJO</div>
        <div className="workspace"><div className="workspace-avatar">P</div><div><b>Persianas 360</b><small>Equipo principal</small></div><ChevronRight size={15}/></div>
        <div className="nav-label">GESTIÓN</div>
        <nav>{nav.map(item => <button key={item.label} className={active === item.label ? 'nav-item active' : 'nav-item'} onClick={() => { setActive(item.label); setMobileNav(false) }}><item.icon size={17}/>{item.label}{item.label === 'Intervenciones' && <span className="nav-count">3</span>}</button>)}</nav>
        <div className="nav-label tools-label">SISTEMA</div>
        <button className="nav-item"><SlidersHorizontal size={17}/>Catálogo técnico</button>
        <button className="nav-item"><Settings size={17}/>Configuración</button>
        <div className="sidebar-bottom"><div className="online-dot"/> <span>Prototipo local</span><span className="version">v0.1</span></div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <button className="icon-button menu-button" onClick={() => setMobileNav(true)} aria-label="Abrir menú"><Menu size={20}/></button>
          <div className="breadcrumb">Workspace <ChevronRight size={14}/> <b>{active}</b></div>
          <div className="top-actions"><span className="today">MIÉRCOLES, 11 NOV 2026</span><button className="icon-button notification" aria-label="Notificaciones"><Bell size={18}/><i/></button><div className="user-avatar">HV</div></div>
        </header>

        <div className="content">
          <section className="page-heading">
            <div><div className="eyebrow">CENTRO DE OPERACIONES</div><h1>Buenos días, equipo.</h1><p>Controla cada intervención con precisión y trazabilidad.</p></div>
            <button className="primary-button" onClick={() => { setShowWizard(true); setStep(0) }}><Plus size={17}/> Nueva inspección</button>
          </section>

          <section className="metric-grid">
            <Metric icon={<ClipboardCheck size={18}/>} label="Intervenciones abiertas" value="03" note="2 requieren seguimiento" />
            <Metric icon={<Clock3 size={18}/>} label="Pendientes de aprobación" value="02" note="Presupuestos enviados" />
            <Metric icon={<ShieldCheck size={18}/>} label="Inspecciones completas" value="12" note="Este mes" />
            <Metric icon={<Activity size={18}/>} label="Trazabilidad documental" value="100%" note="En expedientes cerrados" />
          </section>

          <section className="dashboard-grid">
            <div className="panel inspection-panel">
              <div className="panel-heading"><div><div className="eyebrow">SESIÓN DE DEMOSTRACIÓN</div><h2>Inspección en curso</h2></div><span className="status-pill"><i/> En progreso</span></div>
              <div className="asset-banner"><div className="asset-icon"><Wrench size={21}/></div><div className="asset-info"><b>Persiana salón · PRS-0001</b><span>Aluminio · Motorizada · Vivienda demo</span></div><span className="asset-tag">DEMO</span></div>
              <div className="progress-row"><span>Avance del protocolo</span><b>{progress}%</b></div>
              <div className="progress-track"><div style={{width: progress + '%'}}/></div>
              <div className="check-list">{checks.slice(0, 5).map(item => <div className="check-row" key={item.id}><div className={item.status === 'Pendiente' ? 'check-number' : 'check-number complete'}>{item.status === 'Pendiente' ? item.id.toString().padStart(2,'0') : <Check size={14}/>}</div><div className="check-copy"><b>{item.title}</b><small>{item.detail}</small></div><span className={`mini-status ${item.status === 'Pendiente' ? 'pending' : 'ok'}`}>{item.status}</span></div>)}</div>
              <button className="text-button" onClick={() => setShowWizard(true)}>Continuar inspección <ArrowRight size={15}/></button>
            </div>

            <div className="right-column">
              <div className="panel quick-panel"><div className="panel-heading"><div><div className="eyebrow">ACCESO RÁPIDO</div><h2>Crear expediente</h2></div><div className="soft-icon"><Plus size={18}/></div></div><p>Inicia una visita y documenta cada punto con evidencia.</p><button className="secondary-button" onClick={() => setShowWizard(true)}>Iniciar protocolo <ArrowRight size={15}/></button></div>
              <div className="panel activity-panel"><div className="panel-heading"><div><div className="eyebrow">ACTIVIDAD RECIENTE</div><h2>Últimos movimientos</h2></div></div><ActivityLine title="Inspección creada" desc="PRS-0001 · Vivienda demo" time="Hace 12 min" color="blue"/><ActivityLine title="Presupuesto preparado" desc="EXP-0024 · Borrador" time="Hace 1 h" color="gold"/><ActivityLine title="Expediente cerrado" desc="EXP-0021 · Demo" time="Ayer" color="green"/></div>
            </div>
          </section>

          <section className="panel records-panel"><div className="panel-heading"><div><div className="eyebrow">INVENTARIO DE DEMOSTRACIÓN</div><h2>Activos recientes</h2></div><div className="search-box"><Search size={15}/><input value={query} onChange={e => setQuery(e.target.value)} placeholder="Buscar activo..."/></div></div>{filtered.map((item,i)=><div className="record-row" key={item}><div className="record-symbol"><Wrench size={16}/></div><div className="record-name"><b>{item}</b><small>Vivienda demo · Actualizado hoy</small></div><span className="record-state">{i === 0 ? 'En inspección' : 'Registrada'}</span><ChevronRight size={16}/></div>)}{filtered.length === 0 && <p className="empty-state">No hay activos que coincidan con la búsqueda.</p>}</section>
          <footer>Persianas 360 <span>·</span> Prototipo de interfaz · Datos ficticios, no usar en intervenciones reales.</footer>
        </div>
      </main>

      {showWizard && <div className="modal-backdrop"><section className="wizard-modal"><div className="wizard-top"><div><div className="eyebrow">PROTOCOLO GUIADO · DEMOSTRACIÓN</div><h2>Nueva inspección técnica</h2></div><button className="icon-button" onClick={() => setShowWizard(false)} aria-label="Cerrar"><X size={19}/></button></div><div className="wizard-steps">{modules.map((m,i)=><button key={m} className={step===i?'wizard-step current':step>i?'wizard-step passed':'wizard-step'} onClick={()=>setStep(i)}><span>{step>i?<Check size={12}/>:i+1}</span><small>{m}</small></button>)}</div><div className="wizard-body">{step===0?<><h3>Identificación del activo</h3><p>Datos de ejemplo para validar el recorrido. No introduzcas información real de clientes en este prototipo.</p><div className="form-grid"><Field label="Código de activo" value="PRS-0001"/><Field label="Ubicación" value="Salón · Vivienda demo"/><label className="field"><span>Material</span><select><option>Aluminio</option><option>PVC</option><option>Otro</option></select></label><label className="field"><span>Accionamiento</span><select><option>Motorizado</option><option>Manual</option></select></label></div></>:step===1||step===2?<><h3>{modules[step]}</h3><p>Evalúa cada criterio. Si marcas incidencia, añade una observación y evidencia antes de cerrar el punto.</p><div className="wizard-checks">{checks.slice(step===1?0:4,step===1?4:7).map(item=><div className="wizard-check" key={item.id}><div><b>{item.title}</b><small>{item.detail}</small></div><select value={item.status} onChange={e=>updateStatus(item.id,e.target.value as CheckStatus)}><option>Pendiente</option><option>Conforme</option><option>Incidencia</option><option>No aplica</option></select></div>)}</div><button className="upload-placeholder"><ImagePlus size={18}/> Adjuntar evidencia (disponible en siguiente iteración)</button></>:<><h3>{modules[step]}</h3><p>Este módulo se completará en la siguiente iteración del MVP. El protocolo técnico completo está documentado en el repositorio.</p><div className="coming-soon"><ShieldCheck size={24}/><b>Registro trazable en preparación</b><span>La versión conectada guardará usuario, fecha, resultado y evidencias.</span></div></>}</div><div className="wizard-footer"><span>Paso {step+1} de {modules.length}</span><div><button className="secondary-button" onClick={()=>step===0?setShowWizard(false):setStep(step-1)}> {step===0?'Cancelar':'Anterior'}</button><button className="primary-button" onClick={()=>step===modules.length-1?setShowWizard(false):setStep(step+1)}>{step===modules.length-1?'Finalizar demo':'Continuar'} <ArrowRight size={15}/></button></div></div></section></div>}
    </div>
  )
}

function Metric({icon,label,value,note}:{icon:React.ReactNode;label:string;value:string;note:string}) { return <div className="metric-card"><div className="metric-top"><span className="metric-icon">{icon}</span><span className="metric-note">{note}</span></div><strong>{value}</strong><span className="metric-label">{label}</span></div> }
function ActivityLine({title,desc,time,color}:{title:string;desc:string;time:string;color:string}) { return <div className="activity-line"><i className={color}/><div><b>{title}</b><small>{desc}</small></div><time>{time}</time></div> }
function Field({label,value}:{label:string;value:string}) { return <label className="field"><span>{label}</span><input defaultValue={value}/></label> }

export default App
