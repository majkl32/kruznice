<!doctype html>
<html lang="cs">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Kružnice - webapp</title>
</head>
<body>
  <div id="root"></div>

  <!-- React + ReactDOM from CDN -->
  <script crossorigin src="https://unpkg.com/react@18/umd/react.development.js"></script>
  <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
  <!-- html2canvas + jspdf for PDF export -->
  <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>

  <style>
    body { font-family: Inter, Roboto, Arial; padding: 16px; background:#f7f7fb }
    .app { max-width:1100px; margin:0 auto; display:grid; grid-template-columns: 380px 1fr; gap:16px }
    .card{ background: white; border-radius:8px; padding:12px; box-shadow: 0 4px 14px rgba(20,20,40,0.06)}
    label{display:block; margin-top:8px; font-size:13px}
    input, select{ width:100%; padding:8px; margin-top:6px; box-sizing:border-box }
    canvas{ background:linear-gradient(180deg,#fff,#fafaff); border:1px solid #e6e6f0; display:block; width:100%; height:600px }
    .row{ display:flex; gap:8px }
    .muted{ color:#666; font-size:12px }
    .footer{ margin-top:12px; display:flex; gap:8px }
  </style>

  <script type="text/javascript">
  const e = React.createElement;
  const { useState, useRef, useEffect } = React;

  function App(){
    const [cx, setCx] = useState(0);
    const [cy, setCy] = useState(0);
    const [r, setR] = useState(5);
    const [n, setN] = useState(12);
    const [unit, setUnit] = useState('m');
    const [dotColor, setDotColor] = useState('#ff3b30');
    const [authorName, setAuthorName] = useState('Tvé jméno');
    const [contact, setContact] = useState('email@example.com');

    const canvasRef = useRef(null);
    const containerRef = useRef(null);

    // scale: map model units to pixels
    const width = 820; const height = 600; const margin = 50;

    function draw(){
      const canvas = canvasRef.current;
      if(!canvas) return;
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext('2d');
      // clear
      ctx.clearRect(0,0,width,height);

      // axes center in middle
      const midX = width/2; const midY = height/2;

      // scale: choose pxPerUnit so circle fits
      const pxPerUnit = Math.min((width - margin*2)/( (Math.abs(cx)+Math.abs(r))*2 + 2), (height - margin*2)/((Math.abs(cy)+Math.abs(r))*2 + 2)) || 40;

      // draw grid lines and axes with numeric ticks
      ctx.save();
      ctx.strokeStyle = '#e6e6f0'; ctx.lineWidth = 1;
      // vertical grid
      const unitsX = Math.floor((width - margin*2)/pxPerUnit/2)*2;
      for(let i=-20;i<=20;i++){
        const x = midX + i*pxPerUnit;
        if(x < margin || x > width-margin) continue;
        ctx.beginPath(); ctx.moveTo(x, margin); ctx.lineTo(x, height-margin); ctx.stroke();
      }
      // horizontal grid
      for(let j=-20;j<=20;j++){
        const y = midY + j*pxPerUnit;
        if(y < margin || y > height-margin) continue;
        ctx.beginPath(); ctx.moveTo(margin, y); ctx.lineTo(width-margin, y); ctx.stroke();
      }
      // axes
      ctx.strokeStyle = '#333'; ctx.lineWidth = 1.2;
      ctx.beginPath(); ctx.moveTo(margin, midY); ctx.lineTo(width-margin, midY); ctx.stroke(); // x
      ctx.beginPath(); ctx.moveTo(midX, margin); ctx.lineTo(midX, height-margin); ctx.stroke(); // y

      // ticks and numbers
      ctx.fillStyle = '#222'; ctx.font = '12px Arial'; ctx.textAlign='center'; ctx.textBaseline='top';
      for(let i=-10;i<=10;i++){
        const x = midX + i*pxPerUnit;
        if(x < margin || x > width-margin) continue;
        ctx.beginPath(); ctx.moveTo(x, midY-6); ctx.lineTo(x, midY+6); ctx.stroke();
        ctx.fillText((i).toString() + ' ' + unit, x, midY+8);
      }
      ctx.textAlign='right'; ctx.textBaseline='middle';
      for(let j=-8;j<=8;j++){
        const y = midY + j*pxPerUnit;
        if(y < margin || y > height-margin) continue;
        ctx.beginPath(); ctx.moveTo(midX-6, y); ctx.lineTo(midX+6, y); ctx.stroke();
        ctx.fillText(( -j).toString() + ' ' + unit, midX-8, y);
      }

      // draw circle
      const circleX = midX + cx*pxPerUnit;
      const circleY = midY - cy*pxPerUnit;
      ctx.beginPath(); ctx.strokeStyle = '#0055aa'; ctx.lineWidth = 2; ctx.arc(circleX, circleY, r*pxPerUnit, 0, Math.PI*2); ctx.stroke();

      // compute points
      const pts = [];
      for(let i=0;i<n;i++){
        const angle = 2*Math.PI * i / n;
        const x = cx + r * Math.cos(angle);
        const y = cy + r * Math.sin(angle);
        pts.push({x,y,angle});
      }

      // draw points and labels
      for(let i=0;i<pts.length;i++){
        const p = pts[i];
        const px = midX + p.x*pxPerUnit;
        const py = midY - p.y*pxPerUnit;
        ctx.beginPath(); ctx.fillStyle = dotColor; ctx.arc(px, py, 6, 0, Math.PI*2); ctx.fill();
        ctx.fillStyle = '#111'; ctx.font='13px Arial'; ctx.textAlign='left'; ctx.textBaseline='top';
        ctx.fillText((i+1)+" ("+p.x.toFixed(2)+", "+p.y.toFixed(2)+")", px+8, py+4);
      }

      ctx.restore();
    }

    useEffect(()=>{ draw(); }, [cx,cy,r,n,dotColor,unit]);

    async function exportPDF(){
      const container = containerRef.current;
      if(!container) return;
      const canvasEl = canvasRef.current;
      // render the drawing area to image
      const canvasImage = canvasEl.toDataURL('image/png');
      const { jsPDF } = window.jspdf;
      const pdf = new jsPDF({ unit:'mm', format:'a4' });
      pdf.setFontSize(12);
      pdf.text('Kružnice - parametry úlohy', 14, 14);
      pdf.setFontSize(10);
      pdf.text(`Střed: (${cx}, ${cy}) ${unit}`, 14, 22);
      pdf.text(`Poloměr: ${r} ${unit}`, 14, 28);
      pdf.text(`Počet bodů: ${n}`, 14, 34);
      pdf.text(`Barva bodů: ${dotColor}`, 14, 40);
      pdf.text(`Autor: ${authorName}`, 14, 46);
      pdf.text(`Kontakt: ${contact}`, 14, 52);
      // add image
      const imgProps = pdf.getImageProperties(canvasImage);
      const pdfW = 180; const pdfH = (imgProps.height * pdfW) / imgProps.width;
      pdf.addImage(canvasImage, 'PNG', 14, 60, pdfW, pdfH);
      pdf.save('kruzice.pdf');
    }

    return e('div', {className:'app'},
      e('div', {className:'card'},
        e('h3', null, 'Parametry kružnice'),
        e('label', null, 'Střed X (units):'), e('input',{type:'number', value:cx, onChange: (ev)=>setCx(parseFloat(ev.target.value)||0)}),
        e('label', null, 'Střed Y (units):'), e('input',{type:'number', value:cy, onChange: (ev)=>setCy(parseFloat(ev.target.value)||0)}),
        e('label', null, 'Poloměr (units):'), e('input',{type:'number', value:r, min:0, onChange: (ev)=>setR(parseFloat(ev.target.value)||0)}),
        e('label', null, 'Počet bodů:'), e('input',{type:'number', value:n, min:1, step:1, onChange: (ev)=>setN(parseInt(ev.target.value)||1)}),
        e('label', null, 'Jednotka:'), e('input',{type:'text', value:unit, onChange: (ev)=>setUnit(ev.target.value)}),
        e('label', null, 'Barva bodů:'), e('input',{type:'color', value:dotColor, onChange:(ev)=>setDotColor(ev.target.value)}),
        e('hr'),
        e('label', null, 'Autor (pro PDF):'), e('input',{type:'text', value:authorName, onChange:(ev)=>setAuthorName(ev.target.value)}),
        e('label', null, 'Kontakt (pro PDF):'), e('input',{type:'text', value:contact, onChange:(ev)=>setContact(ev.target.value)}),
        e('div',{className:'footer'},
          e('button',{onClick:draw}, 'Vykreslit'),
          e('button',{onClick:exportPDF}, 'Exportovat do PDF')
        ),
        e('p',{className:'muted'}, 'Poznámka: osa X a Y jsou očíslovány s jednotkou.'),
      ),
      e('div', {className:'card', ref:containerRef},
        e('h3', null, 'Náhled'),
        e('canvas', {ref:canvasRef}),
        e('details', null, e('summary', null, 'Informace o aplikaci a použitých technologiích'),
          e('div', {style:{padding:'8px'}},
            e('p', null, 'Autor: vlož si své jméno v poli Autor.'),
            e('p', null, 'Asistent: GPT-5 Thinking mini.'),
            e('p', null, 'Technologie: React (CDN), Canvas API, jsPDF, html2canvas.'),
            e('p', null, 'Funkce: zadání středu, poloměru, počtu bodů, barvy; vykreslení; export do PDF s parametry a obrázkem.'),
          )
        )
      )
    );
  }

  ReactDOM.createRoot(document.getElementById('root')).render(React.createElement(App));
  </script>
</body>
</html>
