// SURAKSHA WIM - Live Dashboard Controller

let ws;

document.addEventListener("DOMContentLoaded", () => {
  refreshDashboard();
  initWebSocket();
  loadCheckpoints();
});

function initWebSocket() {
  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  const wsUrl = `${protocol}//${window.location.host}/ws/live-feed`;

  ws = new WebSocket(wsUrl);

  ws.onopen = () => {
    console.log("[WS] Live feed connected to central backend.");
  };

  ws.onmessage = (event) => {
    try {
      const msg = JSON.parse(event.data);
      if (msg.event === "WEIGHT_RECORDED") {
        handleLiveWeightEvent(msg.data);
      } else if (msg.event === "CHALLAN_PAID") {
        refreshDashboard();
      }
    } catch (e) {
      console.error("[WS] Parse error:", e);
    }
  };

  ws.onclose = () => {
    console.log("[WS] Feed disconnected. Reconnecting in 3s...");
    setTimeout(initWebSocket, 3000);
  };
}

async function refreshDashboard() {
  try {
    const res = await fetch("/api/dashboard/stats");
    const data = await res.json();

    document.getElementById("stat-scans").innerText = data.total_scans_today.toLocaleString();
    document.getElementById("stat-violations").innerText = data.total_violations_today.toLocaleString();
    document.getElementById("stat-fines").innerText = "Rs. " + data.total_fines_collected.toLocaleString();

    renderViolationsTable(data.recent_violations);
  } catch (e) {
    console.error("Failed to load stats:", e);
  }
}

async function loadCheckpoints() {
  try {
    const res = await fetch("/api/locations");
    const locations = await res.json();
    const container = document.getElementById("locations-list");
    container.innerHTML = "";

    locations.forEach(loc => {
      const item = document.createElement("div");
      item.style = "display: flex; justify-content: space-between; align-items: center; background: rgba(15, 23, 42, 0.6); padding: 10px 14px; border-radius: 8px; border: 1px solid #334155;";
      item.innerHTML = `
        <div>
          <div style="font-weight: bold; font-size: 0.9rem;">${loc.name}</div>
          <div style="font-size: 0.75rem; color: #94a3b8;">${loc.highway} • ${loc.active_officers} Officers on Duty</div>
        </div>
        <span class="badge badge-success">ONLINE</span>
      `;
      container.appendChild(item);
    });
  } catch (e) {
    console.error("Failed to load locations:", e);
  }
}

function renderViolationsTable(violations) {
  const tbody = document.getElementById("violations-table-body");
  if (!violations || violations.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: #94a3b8;">No violations recorded yet.</td></tr>`;
    return;
  }

  tbody.innerHTML = violations.map(v => {
    const isPaid = v.status === "PAID";
    return `
      <tr>
        <td style="font-family: monospace; font-weight: bold; color: #38bdf8;">${v.challan_number}</td>
        <td><strong>${v.plate_number}</strong></td>
        <td>${v.measured_weight_kg.toLocaleString()} kg</td>
        <td style="color: #f87171; font-weight: bold;">+${v.excess_weight_kg.toLocaleString()} kg</td>
        <td style="color: #ef4444; font-weight: 800;">Rs. ${v.fine_amount.toLocaleString()}</td>
        <td><span class="badge ${isPaid ? 'badge-success' : 'badge-danger'}">${v.status}</span></td>
        <td>
          ${!isPaid 
            ? `<button class="btn btn-success" style="padding: 4px 8px; font-size: 0.75rem;" onclick="markChallanPaid(${v.id})">Collect Fine</button>` 
            : `<span style="color: #10b981; font-size: 0.75rem;"><i class="fa-solid fa-check"></i> Paid</span>`}
        </td>
      </tr>
    `;
  }).join("");
}

async function markChallanPaid(id) {
  try {
    const res = await fetch(`/api/violations/${id}/pay`, { method: "PATCH" });
    if (res.ok) {
      refreshDashboard();
    }
  } catch (e) {
    alert("Payment update failed");
  }
}

function loadPreset(type) {
  if (type === "overload") {
    document.getElementById("input-plate").value = "CG10AB1234";
    document.getElementById("input-weight").value = "14500";
  } else {
    document.getElementById("input-plate").value = "MH12DE1433";
    document.getElementById("input-weight").value = "15400";
  }
}

async function triggerWeightCheck() {
  const plate = document.getElementById("input-plate").value.trim();
  const weight = parseFloat(document.getElementById("input-weight").value);

  if (!plate || isNaN(weight) || weight <= 0) {
    alert("Please enter a valid plate and weight");
    return;
  }

  try {
    const res = await fetch("/api/weight-check", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sensor_id: "DASHBOARD_LIVE_TEST",
        plate_number: plate,
        measured_weight_kg: weight,
        checkpoint_name: "Raipur Highway Toll Plaza (NH-53)"
      })
    });

    const data = await res.json();
    handleLiveWeightEvent(data);
    refreshDashboard();
  } catch (e) {
    alert("Backend connection failed. Ensure backend is running!");
  }
}

function handleLiveWeightEvent(data) {
  // Update result box
  const resBox = document.getElementById("result-box");
  resBox.style.display = "block";

  document.getElementById("res-plate").innerText = data.plate_number;
  document.getElementById("res-weight").innerText = `${data.measured_weight_kg.toLocaleString()} kg`;
  document.getElementById("res-limit").innerText = `${data.allowed_weight_kg.toLocaleString()} kg`;
  document.getElementById("res-excess").innerText = `+${data.excess_weight_kg.toLocaleString()} kg`;
  document.getElementById("res-fine").innerText = `Rs. ${data.fine_amount.toLocaleString()}`;

  const badge = document.getElementById("res-status-badge");
  const ledRed = document.getElementById("led-red");
  const ledGreen = document.getElementById("led-green");
  const buzzer = document.getElementById("buzzer-status");
  const gate = document.getElementById("gate-status");

  if (data.is_violation) {
    badge.innerHTML = `<span class="badge badge-danger">OVERLOAD VIOLATION</span>`;
    document.getElementById("res-challan").innerText = `E-Challan Issued: ${data.challan_number}`;

    // Actuator Alarm State
    ledRed.className = "actuator-light active-red";
    ledGreen.className = "actuator-light";
    buzzer.className = "actuator-light active-buzzer";
    gate.innerText = "LOCKED";
    gate.style.color = "var(--danger)";

    // Auto reset visual alarm after 4s
    setTimeout(() => {
      ledRed.className = "actuator-light";
      buzzer.className = "actuator-light";
    }, 4000);
  } else {
    badge.innerHTML = `<span class="badge badge-success">NORMAL WEIGHT</span>`;
    document.getElementById("res-challan").innerText = `Weight complies with permissible limit.`;

    // Actuator Pass State
    ledRed.className = "actuator-light";
    ledGreen.className = "actuator-light active-green";
    buzzer.className = "actuator-light";
    gate.innerText = "OPEN";
    gate.style.color = "var(--success)";
  }

  // Prepend to live ticker feed
  const ticker = document.getElementById("live-ticker");
  const item = document.createElement("div");
  item.className = `ticker-item ${data.is_violation ? 'overload' : ''}`;
  item.innerHTML = `
    <div>
      <div style="font-weight: bold; font-size: 0.9rem;">
        ${data.is_violation ? '🚨 OVERLOAD:' : '✅ PASS:'} ${data.plate_number}
      </div>
      <div style="font-size: 0.75rem; color: #94a3b8;">
        Measured: ${data.measured_weight_kg.toLocaleString()} kg (Limit: ${data.allowed_weight_kg.toLocaleString()} kg)
      </div>
    </div>
    <div>
      ${data.is_violation 
        ? `<strong style="color: #ef4444; font-size: 0.85rem;">Fine: Rs. ${data.fine_amount.toLocaleString()}</strong>` 
        : `<span class="badge badge-success">OK</span>`}
    </div>
  `;
  ticker.insertBefore(item, ticker.firstChild);
}
