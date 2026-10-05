import { useEffect, useRef } from "react";
import type { ReactNode } from "react";

export function Modal({ label, onClose, busy = false, children }: {
  label: string; onClose: () => void; busy?: boolean; children: ReactNode;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => { ref.current?.showModal(); }, []);
  return (
    <dialog 
      ref={ref} 
      className="modal-overlay" 
      aria-label={label} 
      onCancel={event => {
        event.preventDefault();
        if (!busy) onClose();
      }}
      onClick={(e) => {
        if (e.target === ref.current && !busy) onClose();
      }}
    >
      {children}
    </dialog>
  );
}
