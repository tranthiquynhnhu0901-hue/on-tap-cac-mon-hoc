
const $ = s => document.querySelector(s);
const cfg = window.APP_CONFIG || {};
const chapterSlug = new URLSearchParams(location.search).get('chapter') || 'chuong-4';
const hasCloud = !!(cfg.SUPABASE_URL && cfg.SUPABASE_ANON_KEY && window.supabase);
const sb = hasCloud ? window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY) : null;
let chapterData=null, attempt=null, questions=[], answers={}, monitorEvents=[], awayStarted=null, heartbeatTimer=null;
const sessionToken = crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).slice(2)+Date.now();

function esc(s=''){return String(s).replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))}
function browserId(){let id=localStorage.getItem('quiz_browser_id');if(!id){id=crypto.randomUUID?crypto.randomUUID():'b-'+Date.now()+'-'+Math.random().toString(36).slice(2);localStorage.setItem('quiz_browser_id',id)}return id}
function identityKey(n,c){return `${chapterSlug}|${n.trim().toLowerCase()}|${c.trim().toLowerCase()}`}

async function loadChapter(){
  const r=await fetch('data/chapter4.json'); chapterData=await r.json();
  $('#introTitle').textContent=chapterData.chapter_title; $('#quizTitle').textContent=chapterData.chapter_title;
}

async function cloudStart(fullName,className){
  const {data,error}=await sb.rpc('start_or_resume_attempt',{p_chapter_slug:chapterSlug,p_full_name:fullName,p_class_name:className,p_browser_id:browserId(),p_session_token:sessionToken});
  if(error) throw error; const row=Array.isArray(data)?data[0]:data;
  const q=await sb.rpc('get_quiz_questions',{p_chapter_slug:chapterSlug}); if(q.error) throw q.error;
  const a=await sb.rpc('get_saved_answers',{p_attempt_id:row.attempt_id}); if(a.error) throw a.error;
  return {attempt:{id:row.attempt_id,number:row.attempt_number,monitoring:row.monitoring_required,mode:'cloud'},questions:q.data.map(x=>({id:x.question_id,no:x.question_no,section:x.section_label,text:x.question_text,options:{A:x.option_a,B:x.option_b,C:x.option_c,D:x.option_d}})),answers:Object.fromEntries((a.data||[]).map(x=>[x.question_id,x.selected_option]))};
}
function demoStore(){return JSON.parse(localStorage.getItem('quiz_demo_store')||'{}')}
function setDemoStore(x){localStorage.setItem('quiz_demo_store',JSON.stringify(x))}
async function demoStart(fullName,className){
  const store=demoStore(), key=identityKey(fullName,className); let rec=store[key];
  if(!rec || rec.status==='submitted'){
    const prior=(rec&&rec.history?rec.history:[]); const num=prior.length+1;
    rec={id:'demo-'+Date.now(),fullName,className,number:num,monitoring:num>=3,status:'active',answers:{},events:[],startedAt:new Date().toISOString(),history:prior};
    store[key]=rec; setDemoStore(store);
  }
  return {attempt:{id:rec.id,number:rec.number,monitoring:rec.monitoring,mode:'demo',identity:key},questions:chapterData.questions.map(q=>({id:'q'+q.no,no:q.no,section:q.section,text:q.text,options:q.options})),answers:rec.answers||{}};
}

async function start(){
  const fullName=$('#fullName').value.trim(), className=$('#className').value.trim();
  $('#startMsg').textContent=''; if(!fullName||!className){$('#startMsg').textContent='Vui lòng nhập đầy đủ Họ và tên và Lớp.';return}
  $('#startBtn').disabled=true; $('#startBtn').textContent='Đang mở bài...';
  try{
    const s=hasCloud?await cloudStart(fullName,className):await demoStart(fullName,className);
    attempt=s.attempt; questions=s.questions; answers=s.answers;
    $('#identityPanel').classList.add('hidden'); $('#quizMain').classList.add('active');
    $('#studentLine').textContent=`${fullName} · Lớp ${className}`; $('#attemptText').textContent=`Lượt ${attempt.number}`;
    if(attempt.monitoring){$('#monitorBadge').classList.remove('hidden'); await enableMonitoring();}
    renderQuestions(); renderNav(); updateProgress();
  }catch(e){$('#startMsg').textContent='Không mở được bài: '+(e.message||e);}
  finally{$('#startBtn').disabled=false;$('#startBtn').textContent='Bắt đầu / Tiếp tục bài'}
}

function renderQuestions(){
  $('#questions').innerHTML=questions.map(q=>`<article class="question ${answers[q.id]?'done':''}" id="q-${q.no}"><div class="q-top"><span class="q-no">Câu ${q.no}</span><span class="q-section">${esc(q.section||'')}</span></div><div class="q-text">${esc(q.text)}</div>${['A','B','C','D'].map(k=>`<label class="option"><input type="radio" name="q_${esc(q.id)}" value="${k}" ${answers[q.id]===k?'checked':''}><strong>${k}.</strong><span>${esc(q.options[k])}</span></label>`).join('')}</article>`).join('');
  document.querySelectorAll('.question input').forEach(el=>el.addEventListener('change',async e=>{const id=e.target.name.slice(2);answers[id]=e.target.value;e.target.closest('.question').classList.add('done');updateProgress();markNav();await persistAnswer(id,e.target.value)}));
}
function renderNav(){ $('#qNav').innerHTML=questions.map(q=>`<button data-no="${q.no}" class="${answers[q.id]?'done':''}">${q.no}</button>`).join(''); document.querySelectorAll('#qNav button').forEach(b=>b.onclick=()=>document.querySelector('#q-'+b.dataset.no).scrollIntoView({behavior:'smooth'}));}
function markNav(){questions.forEach(q=>{const b=document.querySelector(`#qNav button[data-no="${q.no}"]`);b&&b.classList.toggle('done',!!answers[q.id])})}
function updateProgress(){const n=Object.keys(answers).length,total=questions.length;$('#progressText').textContent=`${n}/${total}`;$('#progressBar').style.width=`${Math.round(n/total*100)}%`}
async function persistAnswer(id,val){
  if(attempt.mode==='cloud'){const r=await sb.rpc('save_answer',{p_attempt_id:attempt.id,p_question_id:id,p_selected_option:val});if(r.error)console.warn(r.error)}
  else{const store=demoStore(),rec=store[attempt.identity];rec.answers=answers;store[attempt.identity]=rec;setDemoStore(store)}
}

async function logEvent(type,detail={}){
  if(!attempt?.monitoring)return;
  const ev={type,detail,at:new Date().toISOString()}; monitorEvents.push(ev);
  if(attempt.mode==='cloud'){
    try{await sb.rpc('log_monitor_event',{p_attempt_id:attempt.id,p_session_token:sessionToken,p_event_type:type,p_event_detail:detail})}catch(e){}
  }else{
    const st=demoStore(),rec=st[attempt.identity];rec.events=(rec.events||[]).concat(ev);st[attempt.identity]=rec;setDemoStore(st)
  }
}
async function enableMonitoring(){
  try{if(document.documentElement.requestFullscreen&&!document.fullscreenElement)await document.documentElement.requestFullscreen()}catch(e){logEvent('fullscreen_denied')}
  document.addEventListener('visibilitychange',()=>{if(document.hidden){awayStarted=Date.now();logEvent('tab_hidden')}else{const d=awayStarted?Math.round((Date.now()-awayStarted)/1000):0;awayStarted=null;logEvent('tab_visible',{away_seconds:d})}});
  window.addEventListener('blur',()=>logEvent('window_blur'));
  document.addEventListener('fullscreenchange',()=>{if(!document.fullscreenElement)logEvent('fullscreen_exit')});
  window.addEventListener('pagehide',()=>{logEvent('page_leave')});
  if(attempt.mode==='cloud'){heartbeatTimer=setInterval(()=>sb.rpc('touch_attempt_session',{p_attempt_id:attempt.id,p_session_token:sessionToken}).catch(()=>{}),10000); sb.rpc('touch_attempt_session',{p_attempt_id:attempt.id,p_session_token:sessionToken}).catch(()=>{});}
}

function memeFor(p){if(p===100)return['🏆','QUÁ DỮ!','40/40 — bài làm sạch đẹp như giáo trình.'];if(p>=90)return['🔥','ĐỈNH NÓC!','Kiến thức đang vào form rất đẹp.'];if(p>=70)return['😎','ỔN ÁP!','Nền tảng tốt, xem lại vài câu sai là lên điểm ngay.'];if(p>=50)return['🤔','SUÝT ĐẸP!','Xem phần giải thích bên dưới rồi thử lại nhé.'];return['🥹','CHƯƠNG NÀY ĐANG GỌI TÊN...','Ôn lại từng mục rồi quay lại phục thù!']}

async function submit(){
  const missing=questions.filter(q=>!answers[q.id]).map(q=>q.no); $('#submitNotice').textContent='';
  if(missing.length){$('#submitNotice').textContent=`Bạn còn ${missing.length} câu chưa trả lời: ${missing.join(', ')}.`;document.querySelector('#q-'+missing[0]).scrollIntoView({behavior:'smooth'});return}
  if(!confirm('Bạn đã trả lời đủ '+questions.length+' câu. Nộp bài ngay?'))return;
  $('#submitBtn').disabled=true;$('#submitBtn').textContent='Đang chấm...';
  try{
    let result;
    if(attempt.mode==='cloud'){
      const r=await sb.rpc('submit_attempt',{p_attempt_id:attempt.id,p_session_token:sessionToken});if(r.error)throw r.error;result=Array.isArray(r.data)?r.data[0]:r.data;
      if(typeof result.review==='string')result.review=JSON.parse(result.review);if(typeof result.monitor_summary==='string')result.monitor_summary=JSON.parse(result.monitor_summary);
    }else result=demoSubmit();
    if(heartbeatTimer)clearInterval(heartbeatTimer); showResult(result);
  }catch(e){$('#submitNotice').textContent='Chưa nộp được bài: '+(e.message||e);$('#submitBtn').disabled=false;$('#submitBtn').textContent='Nộp bài'}
}
function demoSubmit(){
  let score=0;const review=chapterData.questions.map(q=>{const selected=answers['q'+q.no],ok=selected===q.correct;if(ok)score++;return{question_no:q.no,question_text:q.text,selected_option:selected,correct_option:q.correct,options:q.options,explanation:q.explanation,topic:q.topic,is_correct:ok}});
  const percent=Math.round(score/chapterData.questions.length*100);const st=demoStore(),rec=st[attempt.identity];const events=rec.events||[];const summary=summarizeEvents(events);rec.status='submitted';rec.score=score;rec.submittedAt=new Date().toISOString();rec.history=[...(rec.history||[]),{score,percent,submittedAt:rec.submittedAt,events}];st[attempt.identity]=rec;setDemoStore(st);return{score,total:chapterData.questions.length,percent,correct_count:score,wrong_count:chapterData.questions.length-score,review,monitor_summary:summary,attempt_number:attempt.number,monitoring_required:attempt.monitoring};
}
function summarizeEvents(events){const c={tab_hidden:0,window_blur:0,fullscreen_exit:0,page_leave:0,concurrent_session:0,total_away_seconds:0};for(const e of events){if(c[e.type]!==undefined)c[e.type]++;if(e.type==='tab_visible')c.total_away_seconds+=Number(e.detail?.away_seconds||0)}return c}
function showResult(r){
  $('#quizMain').classList.remove('active');$('#result').classList.add('active');window.scrollTo({top:0,behavior:'smooth'});
  $('#scoreBig').textContent=`${r.score}/${r.total}`;$('#scoreMeta').textContent=`${r.percent}% · ${r.correct_count} câu đúng · ${r.wrong_count} câu sai · Lượt ${r.attempt_number||attempt.number}`;
  const m=memeFor(Number(r.percent));$('#meme').innerHTML=`<div class="meme-face">${m[0]}</div><strong>${m[1]}</strong><div>${m[2]}</div>`;
  if(r.monitoring_required){const s=r.monitor_summary||{};const total=(s.tab_hidden||0)+(s.window_blur||0)+(s.fullscreen_exit||0)+(s.page_leave||0)+(s.concurrent_session||0);$('#monitorReport').innerHTML=`<div class="monitor-report"><strong>Nhật ký giám sát lượt làm</strong><div style="margin-top:8px;line-height:1.65">Tổng sự kiện được ghi nhận: <b>${total}</b><br>Rời/ẩn tab: <b>${s.tab_hidden||0}</b> · Mất focus: <b>${s.window_blur||0}</b> · Thoát toàn màn hình: <b>${s.fullscreen_exit||0}</b> · Rời/tải lại trang: <b>${s.page_leave||0}</b> · Phiên trình duyệt đồng thời: <b>${s.concurrent_session||0}</b><br>Thời gian ngoài trang ghi nhận được: <b>${s.total_away_seconds||0} giây</b></div></div>`}else $('#monitorReport').innerHTML='';
  const review=Array.isArray(r.review)?r.review:[];$('#review').innerHTML=`<h2>Xem lại toàn bộ câu hỏi</h2>`+review.map(x=>`<article class="review-item ${x.is_correct?'ok':'bad'}"><div class="q-top"><span class="q-no">Câu ${x.question_no} — ${x.is_correct?'Đúng ✅':'Sai ❌'}</span></div><div class="q-text">${esc(x.question_text)}</div><div class="review-answer"><div>Bạn chọn: <strong>${esc(x.selected_option||'—')}. ${esc(x.options?.[x.selected_option]||'')}</strong></div><div>Đáp án đúng: <strong>${esc(x.correct_option)}. ${esc(x.options?.[x.correct_option]||'')}</strong></div></div><div class="exp"><strong>Giải thích:</strong><br>${esc(x.explanation||'')}</div>${x.topic?`<div class="topic"><strong>Nội dung thuộc:</strong><br>${esc(x.topic)}</div>`:''}</article>`).join('');
}

$('#startBtn').onclick=start;$('#submitBtn').onclick=submit;$('#backBtn').onclick=()=>location.href='index.html';loadChapter();
